get '/api/searches.json' do
  return_json do
    cnt = 0
    if params[:id]
      [StoreHelper.object(params[:id])]
    else
      @user = User.find(session[:user_id])
      owner = @user.userid_for_sendbird

      if params[:r]
        TrackerHelper.
          search_for_searches({ :kw     => params[:keywords] || '',
                                :center => params[:c],
                                :radius => params[:r],
                                :by     => owner })

        StoreHelper.
          searches_by_radius(params[:c], params[:r], owner,
                             (params[:keywords]||"").downcase.
                               split(/[[:space:]]+/))
      else
        TrackerHelper.
          search_for_searches({ :kw => params[:keywords] || '',
                                :sw => params[:sw],
                                :ne => params[:ne],
                                :by => owner })

        StoreHelper.
          searches(params[:sw], params[:ne], owner,
                   (params[:keywords]||"").downcase.split(/[[:space:]]+/))
      end
    end.map do |hsh|
      hsh.tap do |h|
        fill_hash(h, cnt+=1)
        h["i18n"] = TranslatorHelper.new("partials.search_obj_resultslist")
        h["resultslist_html"] =
          haml(:"_resultslist_entry", :layout => false, :locals => h)
      end
    end.sort_by { |a| a["ranking_num"] }
  end
end
