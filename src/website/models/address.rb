class Address < ActiveRecord::Base
  belongs_to :user

  def radius_in_meters
    (bounds["radius"] || compute_radius).to_i
  end

  def compute_radius
    sw,ne = ["sw","ne"].map { |a| JSON(bounds[a]) }

    l1 = Geokit::LatLng.new(sw["lat"], sw["lng"])
    l2 = Geokit::LatLng.new(ne["lat"], ne["lng"])
    (l1.distance_to(l2) / 2.0).to_i
  end

  def update_from_params(params)
    update(:street_1  => params[:address],
           :latitude  => params[:lat].to_f,
           :longitude => params[:lng].to_f,
           :bounds    => {
             :radius => params[:radius].to_i,
             :sw => {
               :lat => params[:sw]["latitude"].to_f,
               :lng => params[:sw]["longitude"].to_f,
             }.to_json,
             :ne => {
               :lat => params[:ne]["latitude"].to_f,
               :lng => params[:ne]["longitude"].to_f,
             }.to_json,
           })
  end
end
