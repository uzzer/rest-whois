require 'test_helper'

class WhoisRecordJsonTest < ActionDispatch::IntegrationTest
  include CaptchaHelpers

  def setup
    @original_whitelist_ip = ENV['whitelist_ip']
    ENV['whitelist_ip'] = ''
    stub_request(:get, /google.com\/recaptcha/).to_return(body: '{}')
    enable_captcha
  end

  def teardown
    ENV['whitelist_ip'] = @original_whitelist_ip
    disable_captcha
  end

  def test_json_returns_404_for_missing_domains
    get('/v1/missing-domain.test.json')

    assert_equal(404, response.status)
    response_json = JSON.parse(response.body)
    assert_equal('Domain not found.', response_json['error'])
    assert_equal('missing-domain.test', response_json['name'])
  end

  def test_post_requests_works_as_get
    post('/v1/missing-domain.test.json')

    assert_equal(404, response.status)
    response_json = JSON.parse(response.body)
    assert_equal('Domain not found.', response_json['error'])
    assert_equal('missing-domain.test', response_json['name'])
  end

  def test_discarded_returns_minimal_json
    get('/v1/discarded-domain.test.json')

    response_json = JSON.parse(response.body)
    assert_equal('discarded-domain.test', response_json['name'])
    assert_equal(['deleteCandidate'], response_json['status'])
    refute(response_json.has_key?('admin_contact'))
    refute(response_json.has_key?('registrant'))
  end

  def test_json_all_fields_are_present
    expected_response = {
      'admin_contacts': [{'changed': 'Not Disclosed',
                          'email': 'Not Disclosed',
                          'name': 'Not Disclosed'}],
      'changed': '2018-04-25T14:10:41+03:00',
      'delete': nil,
      'disclaimer': 'The information obtained through .ee WHOIS is subject to database protection according to the Estonian Copyright Act and international conventions. All rights are reserved to Estonian Internet Foundation. Search results may not be used for commercial,advertising, recompilation, repackaging, redistribution, reuse, obscuring or other similar activities. Downloading of information about domain names for the creation of your own database is not permitted. If any of the information from .ee WHOIS is transferred to a third party, it must be done in its entirety. This server must not be used as a backend for a search engine.',
      'dnssec_changed': nil,
      'dnssec_keys': [],
      'email': 'Not Disclosed',
      'expire': '2018-07-25',
      'name': 'privatedomain.test',
      'nameservers': [],
      'nameservers_changed': nil,
      'outzone': nil,
      'registered': '2018-04-25T14:10:41+03:00',
      'registrant': 'Private Person',
      'registrant_changed': 'Not Disclosed',
      'registrant_kind': 'priv',
      'registrar': 'test',
      'registrar_address': 'test, test, test, test',
      'registrar_changed': '2018-04-25T14:10:30+03:00',
      'registrar_phone': nil,
      'registrar_website': nil,
      'status': ['inactive'],
      'tech_contacts': [{'changed': 'Not Disclosed',
                         'email': 'Not Disclosed',
                         'name': 'Not Disclosed'}],
      'contact_form_link': 'http://www.example.com/contact_requests/new?domain_name=privatedomain.test&locale=en'
    }.with_indifferent_access

    get('/v1/privatedomain.test.json')
    response_json = JSON.parse(response.body)
    assert_equal(expected_response, response_json)
  end

  def test_hide_sensitive_data_of_private_entity_when_captcha_is_unsolved
    get '/v1/privatedomain.test', format: :json

    response_json = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'Private Person', response_json[:registrant]
    assert_equal 'Not Disclosed', response_json[:email]
    assert_equal 'Not Disclosed', response_json[:registrant_changed]

    expected_admin_contacts = [
      { name: 'Not Disclosed',
        email: 'Not Disclosed',
        changed: 'Not Disclosed' }
    ]
    expected_tech_contacts = [
      { name: 'Not Disclosed',
        email: 'Not Disclosed',
        changed: 'Not Disclosed' }
    ]

    assert_equal expected_admin_contacts, response_json[:admin_contacts]
    assert_equal expected_tech_contacts, response_json[:tech_contacts]
  end

  def test_hide_sensitive_data_of_legal_entity_when_captcha_is_unsolved
    get '/v1/company-domain.test', format: :json
    response_json = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'Not Disclosed - Visit www.internet.ee for webbased WHOIS', response_json[:email]
    assert_equal 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
                 response_json[:registrant_changed]

    expected_admin_contacts = [
      { name: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        email: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        changed: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS' }
    ]
    expected_tech_contacts = [
      { name: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        email: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        changed: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS' }
    ]

    assert_equal expected_admin_contacts, response_json[:admin_contacts]
    assert_equal expected_tech_contacts, response_json[:tech_contacts]
  end

  def test_show_sensitive_data_of_private_entity_when_ip_is_in_whitelist
    ENV['whitelist_ip'] = '127.0.0.1'

    get '/v1/privatedomain.test', format: :json
    response_json = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'test', response_json[:registrant]
    assert_equal 'owner@privatedomain.test', response_json[:email]
    assert_equal '2018-04-25T14:10:39+03:00', response_json[:registrant_changed]

    expected_admin_contacts = [
      { name: 'Admin Contact',
        email: 'admin-contact@privatedomain.test',
        changed: '2018-04-25T14:10:41+03:00' }
    ]
    expected_tech_contacts = [
      { name: 'Tech Contact',
        email: 'tech-contact@privatedomain.test',
        changed: '2018-04-25T14:10:41+03:00' }
    ]
    assert_equal expected_admin_contacts, response_json[:admin_contacts]
    assert_equal expected_tech_contacts, response_json[:tech_contacts]
  end

  def test_show_sensitive_data_of_legal_entity_when_ip_is_in_whitelist
    ENV['whitelist_ip'] = '127.0.0.1'

    get '/v1/company-domain.test', format: :json
    response_json = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'test', response_json[:registrant]
    assert_equal 'owner@company-domain.test', response_json[:email]
    assert_equal '2018-04-25T14:10:39+03:00', response_json[:registrant_changed]

    expected_admin_contacts = [
      { name: 'Admin Contact',
        email: 'admin-contact@company-domain.test',
        changed: '2018-04-25T14:10:41+03:00' }
    ]
    expected_tech_contacts = [
      { name: 'Tech Contact',
        email: 'tech-contact@company-domain.test',
        changed: '2018-04-25T14:10:41+03:00' }
    ]
    assert_equal expected_admin_contacts, response_json[:admin_contacts]
    assert_equal expected_tech_contacts, response_json[:tech_contacts]
  end

  def test_hide_sensitive_data_of_private_entity_when_ip_is_not_in_whitelist
    ENV['whitelist_ip'] = '127.0.0.2'

    get '/v1/privatedomain.test', format: :json

    response_json = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'Private Person', response_json[:registrant]
    assert_equal 'Not Disclosed', response_json[:email]

    expected_admin_contacts = [
      { name: 'Not Disclosed',
        email: 'Not Disclosed',
        changed: 'Not Disclosed' }
    ]
    expected_tech_contacts = [
      { name: 'Not Disclosed',
        email: 'Not Disclosed',
        changed: 'Not Disclosed' }
    ]

    assert_equal expected_admin_contacts, response_json[:admin_contacts]
    assert_equal expected_tech_contacts, response_json[:tech_contacts]
  end

  def test_hide_sensitive_data_of_legal_entity_when_ip_is_not_in_whitelist
    ENV['whitelist_ip'] = '127.0.0.2'

    get '/v1/company-domain.test', format: :json
    response_json = JSON.parse(response.body, symbolize_names: true)

    assert_equal 'Not Disclosed - Visit www.internet.ee for webbased WHOIS', response_json[:email]
    assert_equal 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
                 response_json[:registrant_changed]

    expected_admin_contacts = [
      { name: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        email: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        changed: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS' }
    ]
    expected_tech_contacts = [
      { name: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        email: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS',
        changed: 'Not Disclosed - Visit www.internet.ee for webbased WHOIS' }
    ]

    assert_equal expected_admin_contacts, response_json[:admin_contacts]
    assert_equal expected_tech_contacts, response_json[:tech_contacts]
  end
end
