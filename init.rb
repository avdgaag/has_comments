ActiveRecord::Base.send(:include, AGW::HasComments)
ActionController::Base.helper(AGW::HasComments::Helpers)