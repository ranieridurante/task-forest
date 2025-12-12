// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
import 'iconify-icon'

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
import LiveReact from './liveReact'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from 'topbar'
import NavBar from './react-components/layout/NavBar'
import NavigationBreadcrumbs from './react-components/layout/NavigationBreadcrumbs'
import WorkflowsPage from './react-components/workflow/WorkflowsPage'
import WorkflowEditorPage from './react-components/workflow-editor/WorkflowEditorPage'
import AppDashboardPage from './react-components/app/AppDashboardPage'
import APIDocumentationPage from './react-components/docs/APIDocumentationPage'
import Sidebar from './react-components/layout/Sidebar'
import ConnectedProviderList from './react-components/providers/ConnectedProviderList'
import MagicFormsPage from 'react-components/magic-forms/MagicFormsPage'
import BillingPage from 'react-components/billing/BillingPage'
import MarketplacePage from 'react-components/marketplace/MarketplacePage'
import MarketplaceListPage from 'react-components/marketplace/MarketplaceListPage'
import WorkflowTemplatePage from 'react-components/marketplace/WorkflowTemplatePage'
import AuthTokenPage from './react-components/docs/AuthTokenPage'
import WorkflowPlayground from './react-components/workflows/WorkflowPlayground'

declare module 'phoenix_live_view' {
  interface SocketOptions {
    longPollFallbackMs?: number
  }
}

declare const window: {
  liveSocket: LiveSocket
  Components: {
    [key: string]: unknown
  }
} & Window

type THooks = {
  [key: string]: unknown
}

const Hooks: THooks = {}

Hooks.LiveReact = LiveReact

const csrfToken =
  document.querySelector("meta[name='csrf-token']")?.getAttribute('content') ||
  ''
const liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' })

window.addEventListener('phx:page-loading-start', () => topbar.show(300))
window.addEventListener('phx:page-loading-stop', () => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// React components to use within Phoenix
window.Components = {
  NavBar,
  Sidebar,
  NavigationBreadcrumbs,
  WorkflowsPage,
  WorkflowEditorPage,
  AppDashboardPage,
  APIDocumentationPage,
  ConnectedProviderList,
  MagicFormsPage,
  BillingPage,
  MarketplacePage,
  MarketplaceListPage,
  WorkflowTemplatePage,
  AuthTokenPage,
  WorkflowPlayground,
}
