require "test_helper"

class UnfurlsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get unfurls_show_url
    assert_response :success
  end

  test "should get search" do
    get unfurls_search_url
    assert_response :success
  end
end
