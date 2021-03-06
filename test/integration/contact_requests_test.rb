require 'test_helper'

class ContactRequestsTest < ActionDispatch::IntegrationTest
  def setup
    super

    @private_domain = whois_records(:privately_owned)
    @valid_contact_request = contact_requests(:valid)
    @expired_contact_request = contact_requests(:expired)
  end

  def test_create_an_contact_email_delivery
    visit(contact_request_path(@valid_contact_request.secret))

    check(option: 'admin_contacts')
    body = begin
      "<p>Message text with <a href='example.com'>link</a>.</p>\n" \
      'There is a next line character before this one.'
    end
    fill_in('email_body', with: body)
    click_link_or_button('Submit')

    assert_text('Your email has been sent.')

    mail = ActionMailer::Base.deliveries.last
    assert_equal(['no-reply@internet.ee'], mail.from)
    assert_equal(['owner@privatedomain.test', 'admin-contact@privatedomain.test'], mail.to)
    assert_equal('Email to domain owner and/or contact', mail.subject)

    friendly_mail_body = mail.body.to_s
    expected_heading = 'You are listed as the contact person for the domain privatedomain.test'
    expected_body_1 = "Message text with link."
    expected_body_2 = "There is a next line character before this one."
    expected_disclaimer = "Eesti Interneti Sihtasutus"

    assert_match(expected_heading, friendly_mail_body)
    assert_match(expected_body_1, friendly_mail_body)
    assert_match(expected_body_2, friendly_mail_body)
    assert_match(expected_disclaimer, friendly_mail_body)
  end

  def test_request_replay_returns_403
    # Visit the page once
    visit(contact_request_path(@valid_contact_request.secret))

    check(option: 'admin_contacts')
    body = 'Old mail body'
    fill_in('email_body', with: body) # Fill in all the form fields
    click_link_or_button('Submit')
    assert_text('Your email has been sent.') # Successfully send an email

    # Visit the page again, and get an error code
    visit(contact_request_path(@valid_contact_request.secret))
    assert_equal(403, page.status_code)
    assert(page.body.empty?)
  end

  # Locale tests start here
  def test_en_locale_in_contact_email_form
    visit(contact_request_path(@valid_contact_request.secret))
    assert_text('Message is limited to 2000 characters.')
    assert_text('All HTML tags are stripped automatically.')
    assert_text('Select the recipients of your email and enter the text.')
    assert(has_link?(href: 'https://www.internet.ee/domains/eif-s-data-protection-policy'))
  end

  def test_et_locale_in_contact_email_form
    visit(contact_request_path(@valid_contact_request.secret, params: { locale: 'et' }))

    assert_text('Teate pikkus on piiratud 2000 märgiga.')
    assert_text('Kõik HTMLi märgendid eemaldatakse automaatselt.')
    assert_text('Vali kellele soovid teate saata ja sisesta oma sõnum.')
    assert(has_link?(href: 'https://www.internet.ee/domeenid/eis-i-isikuandmete-kasutamise-alused'))
  end

  def test_ru_locale_in_contact_email_form
    visit(contact_request_path(@valid_contact_request.secret, params: { locale: 'ru' }))
    assert_text('Максимальная длина сообщения 2000 символов.')
    assert_text('HTML не поддерживается и будет удален автоматически.')
    assert_text('Получатели сообщения:')
    assert(has_link?(href: 'https://www.internet.ee/domains/eif-s-data-protection-policy'))
  end
end
