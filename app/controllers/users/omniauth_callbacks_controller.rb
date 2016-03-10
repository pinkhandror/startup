class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :authenticate_user!

  def all
    auth =  env["omniauth.auth"]
    user = User.from_omniauth(env["omniauth.auth"], current_user)
    if user.persisted?

      if auth.provider  == "google_oauth2"
        @token = auth["credentials"]["token"]
        client = Google::APIClient.new
        client.authorization.access_token = @token
        service = client.discovered_api('calendar', 'v3')

        @result = client.execute(
          :api_method => service.calendar_list.list,
          :parameters => {},
          :headers => {'Content-Type' => 'application/json'})

        list = client.execute(
            :api_method => service.events.list,
            :parameters => {
                'maxResults' => 20,
                'calendarId' => 'primary'})

        puts "Updating first event from list..."

        update_event = list.data.items[0]
        update_event.description = "Updated Description here"
        update_event.summary = "update summary"
        result = client.execute(:api_method => service.events.update,
                                    :parameters => { 'calendarId' => 'primary', 'eventId' => update_event.id},
                                    :headers => {'Content-Type' => 'application/json'},
                                    :body_object => update_event)

        puts "Done with update."


        puts "Inserting new event..."

        new_event = service.events.insert.request_schema.new
        new_event.start = { 'date' => '2016-03-03' } #All day event
        new_event.end = { 'date' => '2016-03-03' }
        new_event.description = "Insert a event"
        new_event.summary = "Insert Event"
        result = client.execute(:api_method => service.events.insert,
                                    :parameters => { 'calendarId' => 'primary'},
                                    :headers => {'Content-Type' => 'application/json'},
                                    :body_object => new_event)

        puts "Done with insert."

        puts "calender events =   #{@result.data}"
        puts "Fetched #{list.data.items.count} events..."

      end
      flash[:notice] = "You are in..!!! Go to edit profile to see the status for the accounts"
      sign_in_and_redirect(user)
    else
      session["devise.user_attributes"] = user.attributes
      redirect_to new_user_registration_url
    end
  end

  alias_method :twitter, :all

  alias_method :google_oauth2, :all

end
