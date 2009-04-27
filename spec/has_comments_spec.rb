require File.dirname(__FILE__) + '/spec_helper'

# Dummy model
class Post < ActiveRecord::Base
  has_comments
end

describe Post do
  before(:each) do
    @post = Post.new

    @comments = mock('comments')
    @approved_comments = mock('approved')
    @approved_comments.stub!(:count).and_return(5)
    @comments.stub!(:approved).and_return(@approved_comments)
    @post.stub!(:comments).and_return(@comments)
  end

  it "should recalculate its number of approved comments" do
    lambda {
      @post.recalculate_approved_comments_count!
    }.should change(@post, :approved_comments_count).to(5)
  end

  describe "open for comments" do
    it "should return a boolean set as option" do
      @post.options[:open] = true
      @post.open_for_comments?.should == true

      @post.options[:open] = false
      @post.open_for_comments?.should == false
    end

    it "should call a method if a symbol is set" do
      @post.should_receive(:open?).and_return('foo')
      @post.options[:open] = :open?
      @post.open_for_comments?.should == 'foo'
    end

    it "should call a Proc if a Proc is set" do
      p = Proc.new { 'foo'}
      p.should_receive(:call).and_return('bar')
      @post.options[:open] = p
      @post.open_for_comments?.should == 'bar'
    end
  end

  describe "authorised for comments" do
    it "should return a boolean set as option" do
      @post.options[:authorisation] = true
      @post.authorised_for_comments?(1).should == true

      @post.options[:authorisation] = false
      @post.authorised_for_comments?(1).should == false
    end

    it "should call a method if a symbol is set" do
      @post.should_receive(:auth?).with(1).and_return('foo')
      @post.options[:authorisation] = :auth?
      @post.authorised_for_comments?(1).should == 'foo'
    end

    it "should call a Proc if a Proc is set" do
      p = Proc.new { 'foo'}
      p.should_receive(:call).with(1).and_return('bar')
      @post.options[:authorisation] = p
      @post.authorised_for_comments?(1).should == 'bar'
    end
  end
end