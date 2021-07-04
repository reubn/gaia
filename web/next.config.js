module.exports = {
  webpack: config => {
    config.resolve.extensions.push('.css', '.module.css', '.json')

    return config
  },
  future: {
    webpack5: true
  }
}
