require File.dirname(__FILE__) + '/spec_helper'

describe Comment do
  before(:each) do
    @post = mock_model(Post,
      :open_for_comments? => true,
      :authorised_for_comments? => true,
      :auto_approve_comments? => false,
      :recalculate_approved_comments_count! => true,
      :options => {}
    )

    @valid_attributes = {
      :name => 'arjan',
      :email => 'arjan@arjan.com',
      :url => 'http://arjan.com',
      :body => 'My body',
      :user_id => 1,
      :commentable_type => 'Post',
      :commentable_id => 1
    }

    @comment = build_comment
  end

  def build_comment(options = {})
    attributes = @valid_attributes.merge(options)
    c = Comment.new attributes
    c.user_id = attributes[:user_id]
    c.commentable_type = attributes[:commentable_type]
    c.commentable_id = attributes[:commentable_id]
    c.commentable = @post
    c
  end

  def self.it_should_require(*attributes)
    attributes.each do |attribute|
      it "should require #{attribute}" do
        @comment.should be_valid
        @comment.send("#{attribute}=", nil)
        @comment.should_not be_valid
        @comment.should have(1).errors_on(attribute)
      end
    end
  end

  it "should create a new instance given valid attributes" do
    @comment.save!
  end

  it_should_require :body

  it "should require name to be at least 3 characters long" do
    @comment.name = 'fo'
    @comment.should_not be_valid
    @comment.name = 'foo'
    @comment.should be_valid
  end

  it "should require name to be at most 200 characters long" do
    @comment.name = 'foo'.ljust(201)
    @comment.should_not be_valid
    @comment.name = 'foo'.ljust(200)
    @comment.should be_valid
  end

  it "should not be valid when the commentable is not open" do
    @post.should_receive(:open_for_comments?).and_return(false)
    @comment.should_not be_valid
    @comment.errors.on(:base).should == 'You cannot comment on this object.'
  end

  it "should not be valid when the user is not authorised" do
    @post.should_receive(:authorised_for_comments?).and_return(false)
    @comment.should_not be_valid
    @comment.errors.on(:base).should == 'You are not allowed to comment on this object.'
  end

  it "should increase the approved comments count" do
    @post.should_receive(:recalculate_approved_comments_count!)
    @comment.approve
    @comment.save!
  end

  it "should not increase the approved comments count for unapproved comments" do
    @post.should_not_receive(:recalculate_approved_comments_count!)
    @comment.save!
  end

  describe "for registered users" do
    before(:each) do
      @comment.name = nil
      @comment.email = nil
    end

    it_should_require :user_id

    it "repeat commenters should be auto-approved if the commentable wants it" do
      @post.stub!(:auto_approve_comments?).and_return(:auto)
      @comment.save!

      c = build_comment
      c.save!
      c.should be_approved
    end


    it "should auto-approve if the commentable wants it" do
      @post.should_receive(:auto_approve_comments?).and_return(true)
      @comment.save
      @comment.should be_approved
    end

    it "should not auto-approve if the commentable doesn't want it" do
      @post.should_receive(:auto_approve_comments?).and_return(false)
      @comment.save
      @comment.should_not be_approved
    end
  end

  describe "for public users" do
    before(:each) do
      @comment.user_id = nil
    end

    it "repeat commenters should be auto-approved if the commentable wants it" do
      @post.stub!(:auto_approve_comments?).and_return(:auto)

      @comment.approve!

      c = build_comment(:user_id => nil)
      c.save!
      c.should be_approved
    end

    it "should auto-approve if the commentable wants it" do
      @post.should_receive(:auto_approve_comments?).and_return(true)
      @comment.save
      @comment.should be_approved
    end

    it "should not auto-approve if the commentable doesn't want it" do
      @post.should_receive(:auto_approve_comments?).and_return(false)
      @comment.save
      @comment.should_not be_approved
    end

    it "should require a valid e-mail address" do
      @comment.email = 'foo'
      @comment.should_not be_valid
      @comment.should have(1).errors_on(:email)

      @comment.email = 'foo@bar.com'
      @comment.should be_valid
    end

    it "should require a valid URL" do
      @comment.url = 'foo'
      @comment.should_not be_valid
      @comment.should have(1).errors_on(:url)

      @comment.url = 'http://foo.com'
      @comment.should be_valid
    end

    it "should not require a URL" do
      @comment.url = nil
      @comment.should be_valid
    end

    it_should_require :name, :email
  end

  describe "handling SPAM" do

    before(:each) do
      Comment.stub!(:akismet_config).and_return({ :key => 'foo', :blog => 'bar'})
      @request = mock('request')
      @request.stub!(:remote_ip).and_return('123')
      @request.stub!(:env).and_return('foo')
      Comment.request = @request
      @post.stub!(:options).and_return({ :check_spam => true })
      Akismetor.stub!(:submit_spam!)
      Akismetor.stub!(:submit_ham!)
      Akismetor.stub!(:spam?)
    end

    it "should not be SPAM by default" do
      @comment.should_not be_spam
    end

    it "should be marked as SPAM" do
      @comment.spam = true
      @comment.should be_spam
    end

    it "should be marked as ham" do
      @comment.spam = false
      @comment.should_not be_spam
    end

    it "should check for spam before saving" do
      @comment.should_receive(:spam_according_to_akismet?).and_return(false)
      @comment.save
      @comment.should_not be_spam
    end

    it "should mark as spam if Akismet thinks it so" do
      @comment.should_receive(:spam_according_to_akismet?).and_return(true)
      @comment.save
      @comment.should be_spam
    end

    it "should submit spam to Akismet" do
      Akismetor.should_receive(:submit_spam!)
      @comment.mark_as_spam
    end

    it "should submit ham to Akismet" do
      Akismetor.should_receive(:submit_ham!)
      @comment.mark_as_ham
    end

    it "should submit ham when marking spam as ham" do
      Akismetor.should_receive(:submit_spam!)
      @comment.should_not be_spam
      @comment.spam = true
    end

    it "should submit spam when marking ham as spam" do
      @comment.spam = true
      @comment.should be_spam
      Akismetor.should_receive(:submit_ham!)
      @comment.spam = false
      @comment.save
    end

    it "should never check for SPAM with registered users" do
      @comment = build_comment(:name => nil, :email => nil)
      Akismetor.should_not_receive(:spam_according_to_akismet?)
      @comment.save
      @comment.should_not be_spam
    end
  end
end