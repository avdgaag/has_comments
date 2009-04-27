module AGW #:nodoc:
  module HasComments
    module InstanceMethods

      # Let the commentable keep track of the number of approved comments
      def recalculate_approved_comments_count!
        update_attribute(:approved_comments_count, comments.approved.count)
      end

      # Return if the current commentable object accepts comments.
      #
      # If `options[:open]` is set to true or false, return that.
      # Else if this is a Proc object or a symbol referencing a method,
      # return the value of those calls.
      def open_for_comments?
        case options[:open]
          when true, false: return options[:open]
          when Symbol:      return send(options[:open])
          when Proc:        return options[:open].call
          else
            return true
        end
      end

      def auto_approve_comments?
        options[:require_approval]
      end

      # Return if the current user is allowed to make comments on this
      # commentable object.
      #
      # If `options[:authorisation]` is set to true or false, return that.
      # Else if this is a Proc object or a symbol referencing a method,
      # return the value of those calls.
      def authorised_for_comments?(user_id)
        case options[:authorisation]
        when true, false: return options[:authorisation]
        when Symbol:      return send(options[:authorisation], user_id)
        when Proc:        return options[:authorisation].call(user_id)
        else
          return true
        end
      end
    end

    module ClassMethods


      # Lazy-load the commenting behaviour.
      #
      # = OPTIONS
      #
      # You can supply the following options to customize this plugin's
      # behaviour:
      #
      # * `open`: callback that tells the plugin if the commentable object
      #   is open for comments. This can be a Proc or a symbol reference to
      #   an instance method. Defaults to `true`.
      # * `require_approval`: determines if comments should be approved
      #   before publication. Possible values are `true`, `false` and `:auto`.
      #   Defaults to `:auto`
      # * `check_spam`: determines if comments should be tested for SPAM.
      #   Defaults to false.
      # * `authorisation`: callback that tells the plugin if the current
      #   user is allowed to make the comment. This can be a Proc or a symbol
      #   reference to an instance method. Defaults to `false`.
      #
      def has_comments(options = {})

        # Only accept Hashes as options
        raise ArgumentError unless options.is_a?(Hash) || options.nil?

        # Set up default options
        options.reverse_merge!({
          :open             => true,
          :require_approval => :auto,
          :check_spam       => false,
          :authorisation    => true
        })

        class_inheritable_accessor :options

        has_many  :comments,
                  :as         => :commentable,
                  :order      => 'created_at DESC',
                  :dependent  => :destroy

        # Use nested models to manage Comments
        accepts_nested_attributes_for :comments, :allow_destroy => true

        include InstanceMethods unless included_modules.include? InstanceMethods

        self.options = options
      end
    end

    def self.included(receiver) #:nodoc:
      receiver.extend ClassMethods
    end
  end
end