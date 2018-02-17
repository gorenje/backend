require 'sinatra'
require 'haml'

module Webapp
  class App < Sinatra::Base
    enable :inline_templates
    set :show_exceptions, :after_handler

    helpers do
      def header_row(line)
        "<tr>" + line.split(/[[:space:]]+/).map { |v| "<th>#{v}</th>"}.
                   join("\n") + "<th>Actions</th></tr>"
      end

      def line_to_row(line,idx)
        content = line.split(/[[:space:]]+/)
        ns = content.first
        name = content[1]

        "<tr>\n" + content.map { |v| "<td>#{v}</td>"}.join("\n") +
          "<td>" + ["delete", "watch", "scale"].map do |verb|
          "<a href='" + request.path + "/" + ns + "/" +
            name + "/" + verb + "'>" + verb + "</a>"
        end.join("&nbsp;") + "</td></tr>"
      end

      def cmdsp(cmd)
        `#{cmd}`.split(/\n/)
      end
    end

    get '/top/nodes' do
      @allrows = cmdsp("kubectl top nodes")
      haml :table, :layout => :layout
    end

    get '/top/pods' do
      @allrows = cmdsp("kubectl top pods --all-namespaces")
      haml :table, :layout => :layout
    end

    get '/ingress/:namespace/:name/delete/:response' do
      if params[:response] == "yes"
        `kubectl delete ingress -n #{params[:namespace]} #{params[:name]}`
      end
      redirect '/ingress'
    end

    get '/ingress/:namespace/:name/delete' do
      @title = "Are you sure?"
      @choices = ["Yes", "No"]
      haml :choice, :layout => :layout
    end

    post '/deployments/:namespace/:name/scale' do
      `kubectl scale deployment -n #{params[:namespace]} #{params[:name]} --replicas=#{params[:scale]}`
      redirect '/deployments'
    end

    get '/deployments/:namespace/:name/scale' do
      @title = "Scale deployment"
      @scale = `kubectl get deployments -n #{params[:namespace]} #{params[:name]} | tail -n +2 | awk '// { print $2; }'`.strip
      haml :scale, :layout => :layout
    end

    get '/pods/:namespace/:name/delete/:response' do
      if params[:response] == "yes"
        `kubectl delete pods -n #{params[:namespace]} #{params[:name]}`
      end
      redirect '/pods'
    end

    get '/pods/:namespace/:name/delete' do
      @title = "Are you sure?"
      @choices = ["Yes", "No"]
      haml :choice, :layout => :layout
    end

    get '/pods/:namespace/:name/watch' do
      kbcfg = ENV['KUBECONFIG']
      system("osascript -e 'tell application \"Terminal\" to do script \"export KUBECONFIG=\\\"#{kbcfg}\\\" ; kubectl logs --follow=true -n #{params[:namespace]} #{params[:name]}\"'")
      redirect '/pods'
    end

    ["deployments","pods","ingress"].each do |element|
      get '/'+element do
        @title = "All " + element.capitalize
        @allrows = cmdsp("kubectl get #{element} --all-namespaces")
        haml :table, :layout => :layout
      end
    end

    get '/top' do
      @title = "Which Top"
      @choices = ["Pods", "Nodes"]
      haml :choice, :layout => :layout
    end

    get '/_cfg' do
      @title = "Configuration"
      haml :config, :layout => :layout
    end

    post '/_cfg' do
      ENV['KUBECONFIG'] = params[:kubeconfig]
      redirect "/"
    end

    get '/' do
      @title = "All Actions"
      haml "", :layout => :layout
    end

    error(404) do
      haml "Action/Page not supported.", :layout => :layout
    end
  end
end

namespace :webapp do
  desc "Run a simple webserver on top of kubectl"
  task :run do
    require 'thin'
    server = Thin::Server.new
    server.app = Webapp::App
    server.start
  end
end


__END__

@@ layout
%html
  :css
    a {
      text-decoration: none;
    }

  %head
    %link{:crossorigin => "anonymous", :href => "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css", :integrity => "sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm", :rel => "stylesheet"}/
    %script{:crossorigin => "anonymous", :integrity => "sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN", :src => "https://code.jquery.com/jquery-3.2.1.slim.min.js"}
    %script{:crossorigin => "anonymous", :integrity => "sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q", :src => "https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js"}
    %script{:crossorigin => "anonymous", :integrity => "sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl", :src => "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"}
    %title= @title || 'No Title'
  %body
    .row
      .col-10
        %a{ :href => "/pods" } Pods
        %a{ :href => "/top" } Top
        %a{ :href => "/ingress" } Ingress
        %a{ :href => "/deployments" } Deployments
      .col-2
        %a{ :href => "/_cfg" } Config
    %hr
    = yield

@@ choice
%h1 Pick and Choose....
%h2= request.path
- @choices.each do |c|
  %a{ :href => request.path + "/#{c.downcase}" }= c
  %br

@@ table
%table.table.table-striped.table-hover
  %thead.thead-dark
    = header_row(@allrows.first)
  %tbody
    - @allrows[1..-1].each_with_index do |row,idx|
      = line_to_row(row,idx)

@@ config
%form{ :action => "/_cfg", :method => :post }
  %label{ :for => :kubeconfig } KubeConfig
  %input{ :id => :kubeconfig, :type => :text, :value => ENV['KUBECONFIG'], :size => 80, :name => :kubeconfig }
  %br
  %input{ :type => :submit, :value => "Update" }

@@ scale
%form{ :action => request.path, :method => :post }
  %h1
    Rescaling
    = params[:namespace]
    = "."
    = params[:name]
  %label{ :for => :scale } Scale
  %input#scale{ :type => :number, :value => @scale, :name => :scale }
  %br
  %input{ :type => :submit, :value => "Update" }
  %a{ :href => "/#{request.path.split(/\//)[1]}" } Cancel
