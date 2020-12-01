require "test_helper"

describe UsersController do
  let(:user){users(:kari)}
  describe "index" do
    it "succeeds when user is logged in" do
      perform_login(user)

      get users_path

      must_respond_with :success
    end


    it "redirects when there is no one logged in" do

      get users_path

      must_respond_with :redirect

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must log in to do that"
    end

  end

  describe "show" do
    it "succeeds for an extant user ID when user is logged in" do
      perform_login(user)
      get user_path(user.id)

      must_respond_with :success
    end

    it "redirectsfor a bogus work ID" do

      get user_path(-2)

      must_respond_with :redirect
    end

    it 'redirects when user is not logged in' do
      get user_path(user.id)

      must_respond_with :redirect

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must log in to do that"
    end
  end

  describe "auth_callback" do
    it "logs in an existing user and redirects to the root path" do
      user = users(:dan)

      expect {
        perform_login(user)
      }.wont_change "User.count"

      must_redirect_to root_path
      expect(session[:user_id]).must_equal user.id
      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully logged in as existing user #{user.username}"
    end

    it "creates an account for a new user and redirects to the root route" do
      user = User.new(provider: "github", uid: 99999, username: "test_user", email: "test@user.com")

      expect {
        perform_login(user)
      }.must_differ "User.count", 1

      must_redirect_to root_path
      expect(session[:user_id]).must_equal(User.find_by(provider: user.provider,
        uid: user.uid, email: user.email).id)
      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully created new user #{user.username} with ID #{user.uid}"
    end

    it "will handle a request with invalid information" do
      user = User.new(provider: "github", uid: nil, username: nil, email: nil)
      expect {
        perform_login(user)
      }.wont_change "User.count"

      must_respond_with :bad_request

    end
  end

  describe "logout" do
    it "will log out a logged in user" do
      user = users(:dan)
      perform_login(user)

      delete logout_path

      must_redirect_to root_path
      expect(session[:user_id]).must_equal nil
      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully logged out!"
    end

    it "will redirect back and give a flash notice if a guest user tries to logout" do
      delete logout_path

      must_redirect_to root_path
      expect(session[:user_id]).must_equal nil
      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You were not logged in!"
    end
  end
end
