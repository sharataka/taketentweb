Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'locations#landing'

    get 'chrome-guess/' => 'locations#chrome_guess'


  # Example of regular route:
    get 'map_page/location/:objectId' => 'locations#guess'
    get 'result_page/location/:objectId/distance/:distance/' => 'locations#result'
    get 'result_level/' => 'locations#result_level'

    get 'find-opponent/location/:objectId' => 'locations#find_opponent'

    # Anon player signs in and needs to get redirected back to challenge page
    get 'find_challenge_link' => 'locations#find_challenge_link'
    
    get 'location/:objectId' => 'locations#standalone'
    # Sign in
    get 'user/signin' => 'locations#signin'
    get 'user/signin/action/' => 'locations#signin_action'

    # Sign up
    get 'user/signup' => 'locations#signup'
    get 'user/signup/action/' => 'locations#signup_action'

    # Log out
    get 'user/logout/action/' => 'locations#logout_action'

    # test page
    get 'test' => 'locations#test'    

    get 'profile'  => 'locations#profile'

    get 'about'  => 'locations#about'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
    resources :locations

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end