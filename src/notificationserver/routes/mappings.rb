get '/mappings' do
  protected!
  @mappings = Mapping.all
  haml :mappings
end

get '/mapping/:id/delete' do
  protected!
  Mapping.find(params[:id]).delete
  redirect "/mappings"
end

get '/mapping/:id/clone' do
  protected!
  @mapping = Mapping.find(params[:id])
  haml :register
end
