defmodule TaskForestWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use TaskForestWeb, :controller` and
  `use TaskForestWeb, :live_view`.
  """
  use TaskForestWeb, :html

  embed_templates "layouts/*"

  def maybe_load_crisp_chat(host) when host in ["app.plomb.ai"] do
    """
    <!-- Crisp Chat -->
    <script type="text/javascript">window.$crisp=[];window.CRISP_WEBSITE_ID="0c1439d1-e48b-4908-9de9-f34c7c064e59";(function(){d=document;s=d.createElement("script");s.src="https://client.crisp.chat/l.js";s.async=1;d.getElementsByTagName("head")[0].appendChild(s);})();</script>
    """
  end

  def maybe_load_crisp_chat(_host), do: nil

  def maybe_load_posthog_script do
    posthog_config = Application.get_env(:task_forest, :posthog)

    if posthog_config[:is_enabled] do
      """
      <script>
          !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="capture identify alias people.set people.set_once set_config register register_once unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled onFeatureFlags getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys onSessionId".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
          posthog.init(\'#{posthog_config[:api_key]}\', {api_host: \'#{posthog_config[:endpoint]}\', person_profiles: 'always'
              })
      </script>
      """
    end
  end

  def maybe_load_admin_scripts(["admin" | _] = _uri_path) do
    """
    <!-- Highlight JSON syntax -->
    <script defer src="https://unpkg.com/pretty-json-custom-element/index.js"></script>
    """
  end

  def maybe_load_admin_scripts(_uri_path), do: nil
end
