# encoding: utf-8

module Charging
  # Represents a Charging domain.
  class Domain < Base
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

    READ_ONLY_ATTRIBUTES = [:token]

    ATTRIBUTES = [ :supplier_name, :address, :city_state, :zipcode, :national_identifier, :description ]

    attr_accessor(*ATTRIBUTES)
    attr_reader(*READ_ONLY_ATTRIBUTES, :account)

    # Initializes a domain instance
    def initialize(attributes, account, response = nil)
      super(attributes, response)
      @account = account
    end

    # Creates current domain at API.
    #
    # API method: <tt>POST /account/domains/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#post-account-domains
    def create!
      super do
        raise 'can not create without a service account' if invalid_account?

        Domain.post_account_domains(account.application_token, attributes)
      end

      reload_attributes_after_create!
    end

    # Destroys current domain at API.
    #
    # API method: <tt>DELETE /account/domains/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#delete-account-domains-uuid
    def destroy!
      super do
        raise 'can not destroy without a service account' if invalid_account?
        raise 'can not destroy a not persisted domain' unless persisted?
        
        Domain.delete_account_domains(self)
      end
    end

    # Finds all domains for a specified account. It requites an ServiceAccount
    # instance, and you should pass <tt>page</tt> and/or <tt>limit</tt> to
    # apply on find.
    #
    # Returns a Collection (Array-like) of Domain
    #
    # API method: <tt>GET /account/domains/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-domains-limit-limit-page-page
    def self.find_all(account, page = DEFAULT_PAGE, limit = DEFAULT_LIMIT)
      Helpers.required_arguments!('service account' => account)

      response = get_account_domains(account, page, limit)

      Collection.new(account, response)
    end

    # Finds a domain by your uuid. It requites an ServiceAccount instance and a
    # String <tt>uuid</tt>.
    #
    # Returns a Domain instance or raises a Http::LastResponseError if something
    # went wrong, like unauthorized request, not found.
    #
    # API method: <tt>GET /account/domains/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-domains-uuid
    def self.find_by_uuid(account, uuid)
      Helpers.required_arguments!('service account' => account, uuid: uuid)

      response = get_account_domain(account, uuid)

      raise_last_response_unless 200, response

      load_persisted_domain(MultiJson.decode(response.body), response, account)
    end

    # Finds a domain by its authentication token. It requites an <tt>token</tt>.
    #
    # Returns a Domain instance or raises a Http::LastResponseError if something
    # went wrong, like unauthorized request, not found.
    #
    # API method: <tt>GET /domain/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-subuser-domain
    def self.find_by_token(token)
      Helpers.required_arguments!('token' => token)

      response = get_domain(token)

      raise_last_response_unless 200, response

      load_persisted_domain(MultiJson.decode(response.body), response)
    end

    def self.load_persisted_domain(attributes, response, account = nil) # :nodoc:
      validate_attributes!(attributes)
      Domain.new(attributes, account, response)
    end

    private

    def reload_attributes_after_create!
      response = Http.get(last_response.headers[:location], account.application_token)

      new_domain = Domain.load_persisted_domain(MultiJson.decode(response.body), response, account)

      (COMMON_ATTRIBUTES + READ_ONLY_ATTRIBUTES).each do |attribute|
        instance_variable_set "@#{attribute}", new_domain.send(attribute)
      end

      self
    end

    def load_errors(*error_messages)
      @errors = error_messages.flatten
    end

    def invalid_account?
      account.nil?
    end

    def self.delete_account_domains(domain)
      token = domain.account.application_token
      Http.delete("/account/domains/#{domain.uuid}/", token, domain.etag)
    end

    def self.post_account_domains(token, attributes)
      Http.post('/account/domains/', token, MultiJson.encode(attributes))
    end

    def self.get_domain(token) # :nodoc:
      Http.get('/domain/', token)
    end

    def self.get_account_domain(account, uuid) # :nodoc:
      Http.get("/account/domains/#{uuid}/", account.application_token)
    end

    def self.get_account_domains(account, page, limit) # :nodoc:
      Http.get("/account/domains/?page=#{page}&limit=#{limit}", account.application_token)
    end

    def self.create_domain_collection_for(response) # :nodoc:
      data = response.code === 200 ? MultiJson.decode(response.body) : []

      Collection.new(data, response)
    end
    
    class Collection < Charging::Collection
      def initialize(account, response)
        super(response, account: account)
      end
      
      def load_object_with(attributes)
        Domain.load_persisted_domain(attributes, last_response, @account)
      end
    end
  end
end
