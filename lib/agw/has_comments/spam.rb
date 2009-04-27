module AGW #:nodoc:
  module HasComments
    module Spam
      module ClassMethods
        # Return the Akismet configuration for comments to use in their
        # communication with the Akismet server.
        def akismet_config
          @akismet_config ||= YAML.load_file("#{RAILS_ROOT}/config/akismet.yml")['akismet'].to_options
        rescue Errno::ENOENT
          raise Exception, 'No configuration for Akismet found in /config/akismet.yml'
        end

        # Return the request object that the controller has set.
        def request
          @request.merge(self.akismet_config)
        end

        # Allow the setting of the request in the class. This allows
        # the comment submitting to Akismet to know about the request.
        def request=(request)
          @request = if request.nil?
            nil
          else
            {
              :user_ip    => request.remote_ip,
              :referrer   => request.env['HTTP_REFERER'],
              :user_agent => request.env['HTTP_USER_AGENT'],
            }
          end
        end
      end

      module InstanceMethods

        # See if this comment is considered SPAM.
        # This submits information about this comment to the Akismet server.
        def spam_according_to_akismet?
          @spam_according_to_akismet = Akismetor.spam?(to_akismet)
        end

        # Submit this comment as SPAM.
        def mark_as_spam
          Akismetor.submit_spam!(to_akismet)
          logger.info 'Submitted SPAM to Akismet'
        end

        # Submit this comment as SPAM and save the record.
        def mark_as_spam!
          mark_as_spam
          save!
        end

        def spam=(new_value)
          if spam? && (new_value == '0' || new_value == false)
            write_attribute(:spam, false)
            mark_as_ham
          elsif !spam? && (new_value == '1' || new_value == true)
            write_attribute(:spam, true)
            mark_as_spam
          end
        rescue NameError
          logger.warn "Attempting to submit to Akismet failed; install Akismetor."
        end

        # Submit this comment as not SPAM.
        def mark_as_ham
          Akismetor.submit_ham!(to_akismet)
          logger.info "Submitted HAM to Akismet"
        end

        # Submit this comment as not SPAM and save the record.
        def mark_as_ham!
          mark_as_ham
          save!
        end

        # An options hash that Akismator can use for communication with
        # Akismet. Take the request object straight from the commentable.
        # The commentable has an attr_accessor defined, it is up to the user
        # to provide it in his controller.
        #
        # If the class Comment does not know about the request an exception
        # will be raised.
        def to_akismet
          @request = {
            :comment_author       => name,
            :comment_author_email => email,
            :comment_author_url   => url,
            :comment_content      => body
          }.merge(Comment.request)
        rescue TypeError
          raise Exception, "Please provide Comment with a request object."
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end