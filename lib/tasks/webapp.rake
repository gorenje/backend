require 'sinatra'
require 'haml'

namespace :webapp do
  desc "Run a simple webserver on top of kubectl"
  task :run do
    require('thin') && Thin::Server.new.tap { |s| s.app = Webapp }.start
  end
end

class Webapp < Sinatra::Base
  enable :inline_templates
  set :show_exceptions, :after_handler
  YesNo = ["Yes", "No"]
  SpcRE = /[[:space:]]+/

  module Kubectl
    extend self
    def kctl(cmdline)
      `kubectl --kubeconfig="#{kbcfg}" #{cmdline}`.split(/\n/)
    end

    def kbcfg(v = nil)
      v.nil? ? ENV['KUBECONFIG'] : (ENV['KUBECONFIG'] = v)
    end

    def namespaces
      get("namespaces")[1..-1].map { |a| a.split(SpcRE)[1] }
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

    def osascript(script)
      system("osascript -e 'tell application \"Terminal\" to do script " +
             "\"kubectl --kubeconfig=\\\"#{kbcfg}\\\" #{script} \"'")
    end

    def busybox(ns = nil)
      ns = ns.nil? ? "" : " -n #{ns}"
      osascript("run -it busybox-#{(rand*1000000).to_i.to_s(16)}" +
                "#{ns} --image=busybox --restart=Never")
    end

    def watch(ns,name) ; osascript("logs --follow=true -n #{ns} #{name}") ; end
    def shell(ns,name) ; osascript("exec -it -n #{ns} #{name} /bin/bash") ; end
  end

  helpers do
    def header_row(line)
      (line + " Actions").split(SpcRE).map { |v| "<th>#{v}</th>" }.join("\n")
    end

    def cell(value)
      o = value =~ /^([0-9]+)(m|Mi|Gi|%|d)/ ? $1 : value
      "<td data-order='#{o}'>#{value}</td>"
    end

    def line_to_row(line,idx)
      (c = line.split(SpcRE)).map { |v| cell(v) }.join("\n") + "<td>" +
        ["delete", "watch", "scale", "shell"].map do |v|
        "<a class='_#{v}' href='#{request.path}/#{c[0]}/#{c[1]}/#{v}'>#{v}</a>"
      end.join("\n") + "</td>"
    end
  end

  post '/deployments/:ns/:name/scale' do
    Kubectl.scale(params[:ns],params[:name],params[:scale])
    redirect '/deployments'
  end

  get '/deployments/:ns/:name/scale' do
    @title = "Scale deployment"
    @scale = Kubectl.deployment(params[:ns],params[:name])[-1].split(SpcRE)[1]
    haml :scale, :layout => :layout
  end

  ["ingress", "deployments", "pods", "services"].each do |cmp|
    get '(/top)?/' + cmp + '/:ns/:name/delete(/:r)?' do
      if params[:r]
        Kubectl.delete(cmp,params[:ns],params[:name]) if params[:r] == "yes"
        redirect "/#{cmp}"
      else
        @title = "Delete #{cmp}"
        haml :choice, :layout => :layout
      end
    end
  end

  get('(/top)?/pods/:ns/:name/scale') { redirect '/deployments' }

  get '(/top)?/pods/:ns/:name/watch' do
    Kubectl.watch(params[:ns], params[:name]) ; redirect('/pods')
  end

  get '(/top)?/pods/:ns/:name/shell' do
    Kubectl.shell(params[:ns], params[:name]) ; redirect('/pods')
  end

  get '/top/:cmp' do
    @title = "All " + params[:cmp] ; @allrows = Kubectl.top(params[:cmp])
    haml :table, :layout => :layout
  end

  ["deployments", "pods", "ingress", "services"].each do |element|
    get '/'+element do
      @title = "All " + element.capitalize ; @allrows = Kubectl.get(element)
      haml :table, :layout => :layout
    end
  end

  get '/top' do
    @title = "Which Top" ; @choices = ["Pods", "Nodes"]
    haml :choice, :layout => :layout
  end

  get '/_busybox(/:r)?' do
    (Kubectl.busybox && halt(200)) if request.xhr?
    (Kubectl.busybox(params[:r]) && redirect("/pods")) if params[:r]
    @title = "Which Namespace" ; @choices = Kubectl.namespaces
    haml :choice, :layout => :layout
  end

  get '/_cfg' do
    @title = "Configuration" ; haml(:config, :layout => :layout)
  end

  post '/_cfg' do
    Kubectl.kbcfg(params[:kubeconfig]) ; redirect "/"
  end

  get '/' do
    @title = "All Actions" && haml("", :layout => :layout)
  end

  error(404) do
    haml "Action/Page not supported.", :layout => :layout
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
        $('a._watch, a._shell, a._busybox').click(function(event){
          $.get($(event.target).attr('href')).fail(function(){alert('n/a');});
          return false;
        });
      })
    .row.border-bottom.pb-2.pt-2.mr-2.ml-2
      .col-4.text-left
        - ["Pods","Top","Ingress","Deployments","Services"].each do |v|
          %a{ :href => "/#{v.downcase}" }= v
      .col-4.text-center
        Kubectl Website
      .col-4.text-right
        %a{ :href => "/_cfg" } Config
        %a._busybox{ :href => "/_busybox" } Busybox
        %a{ :href => "/_busybox" } BusyboxNS
    .row.pt-2
      .col-12= yield

@@ choice
.text-center
  %h1 Pick and Choose
  %h2= request.path
  - (@choices || YesNo).each do |c|
    %a.btn.btn-primary{ :href => "#{request.path}/#{c.downcase}" }= c

@@ table
%table#datatable.table.table-striped.table-hover
  %thead.thead-dark
    %tr= header_row(@allrows.first)
  %tbody
    - @allrows[1..-1].each_with_index do |row,idx|
      %tr= line_to_row(row,idx)

:javascript
  $(document).ready(function(){$('#datatable').DataTable({"pageLength": 100});})

@@ config
%form.text-center{ :action => "/_cfg", :method => :post }
  %label{ :for => :kubeconfig } KubeConfig
  %input{ :id => :kubeconfig, :type => :text, :value => Kubectl.kbcfg, :size => 80, :name => :kubeconfig }
  %input.btn.btn-success{ :type => :submit, :value => "Update" }
  %a.btn.btn-warning{ :href => "/" } Cancel

@@ scale
%form.text-center{ :action => request.path, :method => :post }
  %h1= "Rescaling #{params[:ns]}.#{params[:name]}"
  %label{ :for => :scale } Scale
  %input#scale{ :type => :number, :value => @scale, :name => :scale }
  %input.btn.btn-success{ :type => :submit, :value => "Update" }
  %a.btn.btn-warning{ :href => "/#{request.path.split(/\//)[1]}" } Cancel
