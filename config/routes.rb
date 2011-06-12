Gauge::Application.routes.draw do |map|
  get "heap_viewer/show_class"

  get "heap_viewer/show_instances"

  get "heap_viewer/show_object"

  get "heap_viewer/show"

  get "/heap_viewer" => "heap_viewer#show"

  root :to => "heap_viewer#show"
end
