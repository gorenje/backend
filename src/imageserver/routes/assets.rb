get '/assets' do
  protected!
  @images = Image.all.order(:id).
    page(params[:page]).per_page((params[:per_page] || 10).to_i)
  haml :"assets/index"
end

get '/asset/:id/delete' do
  protected!
  Image.find(params[:id]).tap do |img|
    img.remove_all_images
    img.delete
  end
  redirect back
end

get '/assets/images/:id(/:size)?' do
  begin
    file = if params[:size]
             Image.find_by_params(params).source.send(params[:size]).file
           else
             Image.find_by_params(params).source.file
           end
    content_type "image/#{file.extension}"
    file.read
  rescue Exception => e
    redirect "/assets/images/#{Image.first.id}"
  end
end

post '/assets/upload_with_sha/:sha' do
  protected!
  unless Image.find_by(:sha => params[:sha])
    img = Image.create(:sha => params[:sha])
    img.post_image(params[:file])
    img.save
  end
  "/assets/images/#{params[:sha]}"
end

post '/assets/upload' do
  protected!
  img = Image.create
  img.post_image(params[:file])
  img.save
  "/assets/images/#{img.id}"
end
