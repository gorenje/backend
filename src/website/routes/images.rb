get '/images/marker/blank.svg' do
  generate_svg "blank"
end

get '/images/marker/:number.svg' do
  @number = params[:number]
  @clr    = params[:c] ? params[:c] : "#cccccc"
  generate_svg "marker"
end

get '/images/notifications/:number.svg' do
  @number = params[:number]
  @clr    = params[:c] ? params[:c] : "#555"
  generate_svg(params[:number].to_i == 0 ? "blank" : "notifications")
end
