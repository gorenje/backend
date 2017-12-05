{ "/aboutus" => :aboutus,
  "/contact" => :contact,
}.each do |path, view|
  get path do
    haml :"admin/#{view}"
  end
end
