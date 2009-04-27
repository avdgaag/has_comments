class Comment < ActiveRecord::Base

  # Associations
  belongs_to    :commentable,
                :polymorphic => true,
                :counter_cache => true

  # Validations
  validates_presence_of :body

  validates_presence_of :name, :email, :unless => :registered_user?
  validates_presence_of :user_id, :unless => :public_user?

  validates_length_of :name, :within => 3..200, :allow_blank => true
  validates_format_of :email, :with => AGW::HasComments::Utils.email, :allow_blank => true
  validates_format_of :url, :with => AGW::HasComments::Utils.url, :allow_blank => true

  # Custom validations
  validate      :commentable_is_open
  validate      :authorised_only

  # Callbacks
  before_create :auto_approve
  before_create :no_spam, :if => Proc.new { |c| c.commentable.options[:check_spam] }
  after_save    :update_counter_cache

  # Scopes
  default_scope :order => 'created_at DESC, approved_at DESC'
  named_scope   :approved, :conditions => 'approved_at IS NOT NULL'
  named_scope   :pending, :conditions => 'approved_at IS NULL'

  attr_accessible :name, :email, :url, :body, :approved, :spam

  include AGW::HasComments::Spam

  # Immediately mark this comment as approved and save it to the database.
  def approve!
    approve
    save!
  end

  # Mark this comment as approved.
  def approve
    self.approved_at = Time.now if approved_at.nil?
  end

  # Mark this comment as not approved
  def unapprove
    self.approved_at = nil
  end

  # Helper for use in forms that approved or unapproves a comment based
  # on a checkbox state.
  def approved=(new_time)
    case new_time
    when '1': approve
    when '0': unapprove
    end
  end

  # Return whether this comment is approved or not.
  # This method is aliased as #approved so it can be used sensibly in forms.
  def approved?
    !approved_at.nil?
  end
  alias_method :approved, :approved?

  # Get the user that characterises this comment, that is: his ID or
  # combination of name, e-mail and URL.
  def user_attributes
    if registered_user?
      { :user_id => user_id }
    elsif public_user?
      { :name => name, :email => email }
    end
  end

  # Given a comment find out if the user (the user or the combination of
  # name, e-mail and url) has been approved before.
  def self.auto_approve?(comment)
    exists? comment.user_attributes
  end

private

  # Helper for the validation, determining if the current user is registerd
  # or not. If he is, we should require a user_id. If he's not, we
  # should require a name and e-mail.
  def registered_user?
    !user_id.nil?
  end

  def public_user?
    name && email
  end

  # Before_save callback. Check for SPAM before we save the record.
  def no_spam
    self.spam = spam_according_to_akismet?
    true # don't stop the saving
  end

  # Before create callback, that will either approve, not approve or try
  # to auto_approve this comment before it is saved, based on the
  # commentable's preference.
  def auto_approve
    approve if commentable.auto_approve_comments? == true || (commentable.auto_approve_comments? == :auto && Comment.auto_approve?(self))
  end

  # Callback after_create. Make sure the counter cache is the commentable
  # object is updated, both the total count as the approved count.
  def update_counter_cache
    commentable.recalculate_approved_comments_count! if approved_at_changed?
  end

  # Custom validation. This checks to see if the commentable object is
  # actually open for comments.
  def commentable_is_open
    errors.add_to_base 'You cannot comment on this object.' unless commentable.open_for_comments?
  end

  # Custom validation. This checks to see if the current user is
  # actually allowed to comment.
  def authorised_only
    errors.add_to_base 'You are not allowed to comment on this object.' unless commentable.authorised_for_comments?(self.user_id)
  end
end