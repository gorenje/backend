get '/assets' do
  @images = Image.all.order(:id).
    page(params[:page]).per_page((params[:per_page] || 10).to_i)
  haml :"assets/index"
end

get '/assets/images/:id(/:size)?' do
  begin
    file = if params[:size]
             Image.find(params[:id]).source.send(params[:size]).file
           else
             Image.find(params[:id]).source.file
           end
    content_type "image/#{file.extension}"
    file.read
  rescue Exception => e
    redirect "/assets/images/#{Image.first.id}"
  end
end

post '/assets/upload' do
  img = Image.create
  img.post_image(params[:file])
  img.save
  "/assets/images/#{img.id}"
end

get '/asset/:id/delete' do
  Image.find(params[:id]).tap do |img|
    img.remove_all_images
    img.delete
  end
  redirect back
end
