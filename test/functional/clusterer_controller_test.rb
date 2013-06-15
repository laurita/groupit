require 'test_helper'

class ClustererControllerTest < ActionController::TestCase
  test "should get cluster" do
    get :cluster
    assert_response :success
  end

end
