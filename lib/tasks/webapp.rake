require 'sinatra'
require 'haml'

namespace :webapp do
  desc "Run a simple webserver on top of kubectl"
  task :run do
    require 'thin'
    Thin::Server.new.tap { |s| s.app = Webapp::App }.start
  end
end

module Webapp
  class App < Sinatra::Base
    enable :inline_templates
    set :show_exceptions, :after_handler

    helpers do
      def header_row(line)
        "<tr>" + line.split(/[[:space:]]+/).map { |v| "<th>#{v}</th>" }.
                   join("\n") + "<th>Actions</th></tr>"
      end

      def cell(value)
        o = value =~ /^([0-9]+)(m|Mi|Gi|%|d)/ ? $1 : value
        "<td data-order='#{o}'>#{value}</td>"
      end

      def line_to_row(line,idx)
        content = line.split(/[[:space:]]+/)
        ns, name = [0,1].map { |idx| content[idx] }

        "<tr>\n" + content.map { |v| cell(v) }.join("\n") +
          "<td>" + ["delete", "watch", "scale"].map do |v|
          "<a class='_#{v}' href='#{request.path}/#{ns}/#{name}/#{v}'>#{v}</a>"
        end.join("\n") + "</td></tr>"
      end

      def cmdsp(cmd)
        `#{cmd}`.split(/\n/)
      end
    end

    get '/top/:cmp' do
      @title = "All " + params[:cmp]
      @allrows = cmdsp("kubectl top #{params[:cmp]}" +
                       (params[:cmp] == "pods" ? " --all-namespaces" : ""))
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

    post '/deployments/:ns/:name/scale' do
      `kubectl scale deployment -n #{params[:ns]} #{params[:name]} --replicas=#{params[:scale]}`
      redirect '/deployments'
    end

    get '/deployments/:ns/:name/scale' do
      @title = "Scale deployment"
      @scale =
        cmdsp("kubectl get deployments -n #{params[:ns]} #{params[:name]}").
          last.split(/[[:space:]]+/)[1]
      haml :scale, :layout => :layout
    end

    get '(/top)?/pods/:ns/:name/scale' do
      redirect '/deployments'
    end

    get '(/top)?/pods/:ns/:name/delete/:r' do
      if params[:r] == "yes"
        `kubectl delete pods -n #{params[:ns]} #{params[:name]}`
      end
      redirect '/pods'
    end

    get '(/top)?/pods/:namespace/:name/delete' do
      @title = "Are you sure?"
      @choices = ["Yes", "No"]
      haml :choice, :layout => :layout
    end

    get '(/top)?/pods/:namespace/:name/watch' do
      kbcfg = ENV['KUBECONFIG']
      system("osascript -e 'tell application \"Terminal\" to do script " +
             "\"export KUBECONFIG=\\\"#{kbcfg}\\\" ; kubectl logs " +
             "--follow=true -n #{params[:namespace]} #{params[:name]}\"'")
      redirect '/pods'
    end

    ["deployments", "pods", "ingress"].each do |element|
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

__END__

@@ layout
%html
  %head
    %link{ :href => "https://cdn.datatables.net/v/bs4/dt-1.10.16/datatables.min.css", :type => "text/css", :rel => "stylesheet" }
    %link{:href => "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css", :rel => "stylesheet"}/
    %script{:src => "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js"}
    %script{:src => "https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js"}
    %script{:src => "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"}
    %script{ :src => "https://cdn.datatables.net/v/bs4/dt-1.10.16/datatables.min.js", :type => "text/javascript" }
    %title= @title || 'No Title'
  %body
    :javascript
      $(document).ready(function() {
        $('a._watch').click(function(event){
          jQuery.get($(event.target).attr('href'));
          return false;
        });
      })

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
%center
  %h1 Pick and Choose....
  %h2= request.path
  - @choices.each do |c|
    %a.btn.btn-primary{ :href => request.path + "/#{c.downcase}" }= c

@@ table
%table#datatable.table.table-striped.table-hover
  %thead.thead-dark
    = header_row(@allrows.first)
  %tbody
    - @allrows[1..-1].each_with_index do |row,idx|
      = line_to_row(row,idx)
:javascript
  $(document).ready(function() {
    $('#datatable').DataTable({
      "pageLength": 100
    });
  });

@@ config
%form{ :action => "/_cfg", :method => :post }
  %center
    %label{ :for => :kubeconfig } KubeConfig
    %input{ :id => :kubeconfig, :type => :text, :value => ENV['KUBECONFIG'], :size => 80, :name => :kubeconfig }
    %p
    %input.btn.btn-success{ :type => :submit, :value => "Update" }
    %a.btn.btn-warning{ :href => "/" } Cancel

@@ scale
%form{ :action => request.path, :method => :post }
  %center
    %h1
      Rescaling
      = params[:ns]
      = "."
      = params[:name]
    %label{ :for => :scale } Scale
    %input#scale{ :type => :number, :value => @scale, :name => :scale }
    %p
    %input.btn.btn-success{ :type => :submit, :value => "Update" }
    %a.btn.btn-warning{ :href => "/#{request.path.split(/\//)[1]}" } Cancel
