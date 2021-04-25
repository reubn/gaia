import React from 'react'
import Mousetrap from 'mousetrap'
console.log(Mousetrap)

export default class KeyCombo extends React.Component {
  constructor(props){
    super(props)

    this.bind = this.bind.bind(this)
    this.unbind = this.unbind.bind(this)
  }

  componentDidMount(){
    this.bind(this.props)
  }

  componentWillUpdate({combo: newCombo, handler: newHandler, action: newAction}){
    const {combo, handler, action} = this.props
    if(combo !== newCombo || handler !== newHandler || action === newAction){
      this.unbind({combo, action})
      this.bind({combo: newCombo, handler: newHandler, action: newAction})
    }
  }

  componentWillUnmount(){
    this.unbind(this.props)
  }

  bind({combo, handler, action}){
    Mousetrap.bind(combo, handler, action)
  }

  unbind({combo, action}){
    Mousetrap.unbind(combo, action)
  }

  render(){return null}
}
