module AGW
  module HasComments
    module Helpers
      # Returns a Gravatar URL associated with the email parameter.
      # See http://douglasfshearer.com/blog/gravatar-for-ruby-and-ruby-on-rails
      def gravatar_url(email, options = {})

        # Default highest rating.
        # Rating can be one of G, PG, R X.
        # If set to nil, the Gravatar default of X will be used.
        options[:rating] ||= nil

        # Default size of the image.
        # If set to nil, the Gravatar default size of 80px will be used.
        options[:size] ||= nil

        # Default image url to be used when no gravatar is found
        # or when an image exceeds the rating parameter.
        options[:default] ||= nil

        # Build the Gravatar url.
        grav_url = 'http://www.gravatar.com/avatar.php?'
        grav_url << "gravatar_id=#{Digest::MD5.new.update(email)}"
        grav_url << "&rating=#{options[:rating]}" if options[:rating]
        grav_url << "&size=#{options[:size]}" if options[:size]
        grav_url << "&default=#{options[:default]}" if options[:default]
        return grav_url
      end

      # Returns a Gravatar image tag associated with the email parameter.
      #--
      # TODO: make this work with associated users
      def gravatar_for(comment, options = {})
        email = comment.email or raise ArgumentError, 'Comment should have an e-mail.'

        image_tag gravatar_url(email, options), {
          :alt    => 'Gravatar',
          :size   => '',
          :width  => (options[:size] || '80'),
          :height => (options[:size] || '80')
          :class  => 'gravatar'
      end

      # Shortcut method to a form_for with fields_for a new comment.
      #--
      # TODO: make this work with non-new objects too?
      def comment_form_for(*args)
        form_for(*args) do |f|
          f.fields_for(:comments, Comment.new) do |g|
            yield f, g
          end
        end
      end

      # Return either the name of the author of a given comment,
      # or a link to that author's website with his name as link text
      # if a URL was given.
      #--
      # TODO: do something with user_id.
      def link_to_comment_author(comment)
        if comment.url?
          link_to h(comment.name), h(comment.url), :rel => 'external nofollow'
        else
          h(comment.name)
        end
      end
    end
  end
end