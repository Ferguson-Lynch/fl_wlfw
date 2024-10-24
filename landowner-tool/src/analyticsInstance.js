// Analytics store component to track events and share a global events tracker
import Analytics from 'analytics';
import googleAnalytics from '@analytics/google-analytics';

const analyticsInstance = Analytics({
  app: 'landowner-tool',
  plugins: [
    googleAnalytics({
      measurementIds: ['G-FZFFBB18CL']
      // ,debug: true
    })
  ]
})

export default analyticsInstance