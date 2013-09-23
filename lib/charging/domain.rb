# encoding: utf-8

module Charging
  # Represents a Charging domain.
  class Domain
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

    READ_ONLY_ATTRIBUTES = [:uuid, :etag, :uri, :token]
    ATTRIBUTES = [
      :supplier_name,
      :address,
      :city_state,
      :zipcode,
      :national_identifier,
      :description
    ]

    attr_accessor *ATTRIBUTES
    attr_reader *READ_ONLY_ATTRIBUTES

    # Responds the last http response from the API.
    attr_reader :last_response, :account, :errors

    # Initializes a domain instance
    def initialize(attributes, account, response = nil)
      Helpers.load_variables(self, ATTRIBUTES + READ_ONLY_ATTRIBUTES, attributes)

      @last_response = response
      @account = account
      @errors = []
      @deleted = false
    end

    # Returns true if the Domain exists on Charging service.
    def persisted?
      !!(uuid && etag && uri && token && !deleted?)
    end

    # Returns true if domains already deleted on API
    def deleted?
      !!@deleted
    end

    # Returns a hash with attributes
    def attributes
      Helpers.hashify(self, ATTRIBUTES)
    end

    # Creates current domain at API.
    #
    # API method: <tt>POST /account/domains/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#post-account-domains
    def create!
      @errors = []
      raise 'can not create without a service account' if invalid_account?

      @last_response = Domain.post_account_domains(account.application_token, attributes)

      raise Http::LastResponseError.new(last_response) if last_response.code != 201

      reload_attributes_after_create!
    rescue ::RestClient::Exception => exception
      @last_response = exception.response

      raise Http::LastResponseError.new(last_response)
    ensure
      @errors = [$ERROR_INFO.message] if $ERROR_INFO
    end

    # Destroys current domain at API.
    #
    # API method: <tt>DELETE /account/domains/:uuid</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#delete-account-domains-uuid
    def destroy!
      @errors = []
      raise 'can not destroy without a service account' if invalid_account?
      raise 'can not destroy a not persisted domain' unless persisted?

      @last_response = Domain.delete_account_domains(self)

      raise Http::LastResponseError.new(last_response) if last_response.code != 204

      reload_attributes_after_delete!
    rescue ::RestClient::Exception => exception
      @last_response = exception.response

      raise Http::LastResponseError.new(last_response)
    ensure
      @errors = [$ERROR_INFO.message] if $ERROR_INFO
    end

    # Finds all domains for a specified account. It requites an ServiceAccount
    # instance, and you should pass <tt>page</tt> and/or <tt>limit</tt> to
    # apply on find.
    #
    # Returns a DomainCollection (Array-like) of Domain
    #
    # API method: <tt>GET /account/domains/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-domains-limit-limit-page-page
    def self.find_all(account, page = DEFAULT_PAGE, limit = DEFAULT_LIMIT)
      Helpers.required_arguments!('service account' => account)

      response = get_account_domains(account, page, limit)

      DomainCollection.new(account, response)
    end

    # Finds a domain by your uuid. It requites an ServiceAccount instance and a
    # String <tt>uuid</tt>.
    #
    # Returns a Domain instance or raises a Http::LastResponseError if something
    # went wrong, like unauthorized request, not found.
    #
    # API method: <tt>GET /account/domains/:uuid</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-domains-uuid
    def self.find_by_uuid(account, uuid)
      Helpers.required_arguments!('service account' => account, uuid: uuid)

      response = get_account_domain(account, uuid)

      raise Http::LastResponseError.new(response) if response.code != 200

      load_persisted_domain(MultiJson.decode(response.body), response, account)
    rescue ::RestClient::Exception => exception
      raise Http::LastResponseError.new(exception.response)
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

      raise Http::LastResponseError.new(response) if response.code != 200

      load_persisted_domain(MultiJson.decode(response.body), response)
    rescue ::RestClient::Exception => exception
      raise Http::LastResponseError.new(exception.response)
    end

    def self.load_persisted_domain(attributes, response, account = nil) # :nodoc:
      validate_attributes!(attributes)
      Domain.new(attributes, account, response)
    end

    private

    def reload_attributes_after_delete!
      @deleted = true
      @persisted = false

      self
    end

    def reload_attributes_after_create!
      response = Http.get(last_response.headers[:location], account.application_token)

      new_domain = Domain.load_persisted_domain(MultiJson.decode(response.body), response, account)

      READ_ONLY_ATTRIBUTES.each do |attribute|
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

    def self.validate_attributes!(attributes) # :nodoc:
      keys = attributes.keys.map(&:to_sym)
      diff = keys - (ATTRIBUTES + READ_ONLY_ATTRIBUTES)
      raise ArgumentError, "Invalid attributes for domain: #{attributes.inspect}" if diff.any?
    end

    def self.get_account_domains(account, page, limit) # :nodoc:
      Http.get("/account/domains/?page=#{page}&limit=#{limit}", account.application_token)
    end

    def self.create_domain_collection_for(response) # :nodoc:
      data = response.code === 200 ? MultiJson.decode(response.body) : []

      DomainCollection.new(data, response)
    end
  end

  # Represents a domain collection result for a <tt>Domain.find_all</tt>. It is
  # a delegator for an array of Domain.
  class DomainCollection < SimpleDelegator

    # Responds the last http response from the API.
    attr_reader :last_response

    # Responds the current ServiceAccount instance.
    attr_reader :account

    def initialize(account, response) # :nodoc:
      Helpers.required_arguments!('service account' => account, 'response' => response)

      @account = account
      @last_response = response
      super(load_data_with_response!)
    end

    def load_data_with_response! # :nodoc:
      return [] if last_response.code != 200

      raw_domains = MultiJson.decode(last_response.body)
      raw_domains.map { |raw_domain| load_domain(account, raw_domain) }
    end

    def load_domain(account, attributes) # :nodoc:
      Domain.load_persisted_domain(attributes, last_response, account)
    end
  end
end
