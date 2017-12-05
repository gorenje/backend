get '/mappings' do
  @mappings = Mapping.all
  haml :mappings
end

get '/mapping/:id/delete' do
  Mapping.find(params[:id]).delete
  redirect "/mappings"
end

get '/mapping/:id/clone' do
  @mapping = Mapping.find(params[:id])
  haml :register
end
