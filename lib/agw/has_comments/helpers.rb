module AGW
  module HasComments
    module Helpers
      # Shortcut method to a form_for with fields_for a new comment.
      #
      # TODO: make this work with non-new objects too.
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
      #
      # TODO: do something with user_id.
      def link_to_comment_author(comment)
        if comment.url?
          link_to h(comment.name), h(comment.url), :rel => 'external nofollow'
        else
          h(comment.name)
        end
      end

      # TODO: WIP
      def link_to_comment_approval(comment)
        if comment.approved?
          'Approved at %s' % comment.approved_at.to_s('short')
        else
          render :partial => 'comment_management', :locals => { :comment => comment }
        end
      end
    end
  end
end