# frozen_string_literal: true

# handles cookie policy switching
class CookiesController < ApplicationController
  skip_before_action :verify_authenticity_token

  include ActionView::Helpers::UrlHelper

  FUNCTIONAL_COOKIES = [
   'lang', 'cl_accepted',
   '__cfduid', 'unnec_ac',
   Rails.application.config.session_options[:key]
  ].freeze

  COOKIE_DOC_LINK =
    'https://s3.amazonaws.com/tc-global-prod/download_resources/gb/downloads/12376/Cookies_Policy_English.pdf'

  def index
    render json: { settings: consent_settings, message: 'Cookies' }
  end

  def update
    handle_cookie_switch
    render json: { message: 'Cookie Policy Set' }, status: 200
  end

  private

  def handle_cookie_switch
    clear_unnecessary_cookies unless marketing_accepted?
    set_flag_value
    set_cl_accepted
  end

  def clear_unnecessary_cookies
    request.cookies.except(*FUNCTIONAL_COOKIES).keys.each do |c_k|
      request.cookies.delete(c_k)
    end
  end

  def consent_settings
    { data:
        [{ id: 'functional',
           label: I18n.t('cookies.consent.functional.label'),
           description: I18n.t('cookies.consent.functional.description'),
           required: true },
         { id: 'marketing',
           label: I18n.t('cookies.consent.marketing.label'),
           description: I18n.t('cookies.consent.marketing.description'),
           required: false }],
      translations:
        [{ title: I18n.t('cookies.consent.title'),
           description: I18n.t(
             'cookies.consent.description_html',
             privacy_policy_link: privacy_policy_link,
             cookies_doc_link: cookies_doc_link
           ),
           button: I18n.t('cookies.consent.button') }] }
  end

  def privacy_policy_link
    link_to(I18n.t('cookies.consent.privacy_policy_link'), 'privacy-policy')
  end

  def cookies_doc_link
    link_to(I18n.t('cookies.consent.cookies_doc_link'), COOKIE_DOC_LINK, target: '_blank')
  end

  def set_flag_value
    value = marketing_accepted? ? 'on' : 'off'
    response.set_cookie(
      :unnec_ac,
      value: value, expires: 6.month.from_now, path: '/'
    )
  end

  def set_cl_accepted
    response.set_cookie(
      :cl_accepted,
      value: 'true', expires: 6.month.from_now, path: '/'
    )
  end

  def marketing_accepted?
    params['_json'].detect { |e| e['id'] == 'marketing' }['accepted']
  end
end
