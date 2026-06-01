require "test_helper"

class StudioNotesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get studio_notes_create_url
    assert_response :success
  end

  test "should get destroy" do
    get studio_notes_destroy_url
    assert_response :success
  end
end
