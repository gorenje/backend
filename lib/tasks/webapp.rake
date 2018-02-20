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

    class Kubectl
      class << self
        def kctl(cmdline)
          `kubectl #{cmdline}`.split(/\n/)
        end

        def kbcfg(v = nil)
          v.nil? ? ENV['KUBECONFIG'] : (ENV['KUBECONFIG'] = v)
        end

        def namespaces
          get("namespaces")[1..-1].map { |a| a.split(/[[:space:]]+/)[1] }
        end

        def scale(ns,name,scale)
          kctl("scale deployment -n #{ns} #{name} --replicas=#{scale}")
        end

        def delete(cmp, ns, name)
          kctl("delete #{cmp.to_s} -n #{ns} #{name}")
        end

        def top(cmp)
          kctl("top #{cmp}" + (cmp == "pods" ? " --all-namespaces" : ""))
        end

        def get(cmp)
          kctl("get #{cmp.to_s} --all-namespaces --output=wide")
        end

        def deployment(ns,name)
          kctl("get deployments -n #{ns} #{name}")
        end

        def busybox(ns = nil)
          ns = ns.nil? ? "" : "-n #{ns}"
          name = "busybox-#{(rand*1000000).to_i.to_s(16)}"
          system("osascript -e 'tell application \"Terminal\" to do script " +
                 "\"export KUBECONFIG=\\\"#{kbcfg}\\\" ; kubectl run " +
                 "-i -t #{name} #{ns} --image=busybox --restart=Never\"'")
        end

        def watch(ns,name)
          system("osascript -e 'tell application \"Terminal\" to do script " +
                 "\"export KUBECONFIG=\\\"#{kbcfg}\\\" ; kubectl logs " +
                 "--follow=true -n #{ns} #{name}\"'")
        end

        def shell(ns,name)
          system("osascript -e 'tell application \"Terminal\" to do script " +
                 "\"export KUBECONFIG=\\\"#{kbcfg}\\\" ; kubectl exec -it " +
                 "-n #{ns} #{name} /bin/bash\"'")
        end
      end
    end

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
          "<td>" + ["delete", "watch", "scale", "shell"].map do |v|
          "<a class='_#{v}' href='#{request.path}/#{ns}/#{name}/#{v}'>#{v}</a>"
        end.join("\n") + "</td></tr>"
      end
    end

    get '/top/:cmp' do
      @title = "All " + params[:cmp]
      @allrows = Kubectl.top(params[:cmp])
      haml :table, :layout => :layout
    end

    get '/ingress/:ns/:name/delete/:r' do
      Kubectl.delete(:ingress,params[:ns],params[:name]) if params[:r] == "yes"
      redirect '/ingress'
    end

    get '/ingress/:namespace/:name/delete' do
      @title = "Are you sure?"
      @choices = ["Yes", "No"]
      haml :choice, :layout => :layout
    end

    post '/deployments/:ns/:name/scale' do
      Kubectl.scale(params[:ns],params[:name],params[:scale])
      redirect '/deployments'
    end

    get '/deployments/:ns/:name/scale' do
      @title = "Scale deployment"
      @scale = Kubectl.deployment(params[:ns],params[:name])[-1].
                 split(/[[:space:]]+/)[1]
      haml :scale, :layout => :layout
    end

    get '/deployments/:ns/:name/delete' do
      @title = "Delete deployment"
      @choices = ["Yes", "No"]
      haml :choice, :layout => :layout
    end

    get '/deployments/:ns/:name/delete/:r' do
      Kubectl.
        delete(:deployments, params[:ns], params[:name]) if params[:r] == "yes"
      redirect '/deployments'
    end

    get '(/top)?/pods/:ns/:name/scale' do
      redirect '/deployments'
    end

    get '(/top)?/pods/:ns/:name/delete/:r' do
      Kubectl.delete(:pods, params[:ns], params[:name]) if params[:r] == "yes"
      redirect '/pods'
    end

    get '(/top)?/pods/:namespace/:name/delete' do
      @title = "Are you sure?"
      @choices = ["Yes", "No"]
      haml :choice, :layout => :layout
    end

    get '(/top)?/pods/:namespace/:name/watch' do
      Kubectl.watch(params[:namespace], params[:name])
      redirect '/pods'
    end

    get '(/top)?/pods/:namespace/:name/shell' do
      Kubectl.shell(params[:namespace], params[:name])
      redirect '/pods'
    end

    ["deployments", "pods", "ingress", "services"].each do |element|
      get '/'+element do
        @title = "All " + element.capitalize
        @allrows = Kubectl.get(element)
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

    get '/_busybox(/:r)?' do
      (Kubectl.busybox && halt(200)) if request.xhr?

      if params[:r]
        Kubectl.busybox(params[:r])
        redirect "/pods"
      else
        @title = "Which Namespace"
        @choices = Kubectl.namespaces
        haml :choice, :layout => :layout
      end
    end

    post '/_cfg' do
      Kubectl.kbcfg(params[:kubeconfig])
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
          $.get($(event.target).attr('href'))
            .fail(function(){alert('not implemented.');});
          return false;
        });
        $('a._shell').click(function(event){
          $.get($(event.target).attr('href'))
            .fail(function(){alert('not implemented.');});
          return false;
        });
        $('a._busybox').click(function(event){
          $.get($(event.target).attr('href'))
            .fail(function(){alert('not implemented.');});
          return false;
        });
      })

    .row
      .col-4
        %a{ :href => "/pods" } Pods
        %a{ :href => "/top" } Top
        %a{ :href => "/ingress" } Ingress
        %a{ :href => "/deployments" } Deployments
        %a{ :href => "/services" } Services
      .col-4.text-center
        Kubectl Website
      .col-4.text-right
        %a{ :href => "/_cfg" } Config
        %a._busybox{ :href => "/_busybox" } Busybox
        %a{ :href => "/_busybox" } BusyboxNS
    %hr
    = yield

@@ choice
%center
  %h1 Pick and Choose
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
    %input{ :id => :kubeconfig, :type => :text, :value => Kubectl.kbcfg, :size => 80, :name => :kubeconfig }
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
