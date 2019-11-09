import React, {
  Component,
} from 'react'
import {
  View,
  requireNativeComponent,
  NativeModules,
  AppState,
  Platform,
} from 'react-native'

import PropTypes from 'prop-types';

const ScannerManager = Platform.OS === 'ios' ? NativeModules.IDCardScanner : NativeModules.ScannerModule;

export default class Scanner extends Component {

  static defaultProps = {
    scannerRectWidth: 205,
    scannerRectTop: 20,
    scannerRectBorderWidth:1.5,
    scannerRectCornerRadius:12,
    scannerRectColor: `#FFFFFF`,
    isAutoReg:false
    // barCodeTypes: Object.values(ScannerManager.barCodeTypes),
    // scannerRectHeight: 255,
    // scannerRectLeft: 0,
    // scannerLineInterval: 3000,
  }

  static propTypes = {
    ...View.propTypes,
    onIDScannerResult: PropTypes.func.isRequired,
    scannerRectWidth: PropTypes.number,
    scannerRectTop: PropTypes.number,
    scannerRectBorderWidth:PropTypes.number,
    scannerRectCornerRadius:PropTypes.number,
    scannerRectColor: PropTypes.string,
    isAutoReg:PropTypes.bool
    // barCodeTypes: PropTypes.array,
    // scannerRectHeight: PropTypes.number,
    // scannerRectLeft: PropTypes.number,
    // scannerLineInterval: PropTypes.number,
    // scannerRectCornerColor: PropTypes.string,
  }

  _onIDScannerResult;

  constructor(props){
    super(props);
    if(Platform.OS === 'ios'){
      this._onIDScannerResult = (ev)=>{
        if(ev.nativeEvent.data.cardFace === 'front'){
          let idNum = ev.nativeEvent.data.cardNum;
          let birth = "";
          if(idNum.length === 18){
            birth = idNum.substr(6,4)+'-'+idNum.substr(10,2)+'-'+idNum.substr(12,2);
          }else{
            birth = '19'+idNum.substr(6,2)+'-'+idNum.substr(8,2)+'-'+idNum.substr(10,2);
          }
          ev.nativeEvent.data.birth = birth;
        }
        this.props.onIDScannerResult(ev);
      }
    }else{
      this._onIDScannerResult = this.props.onIDScannerResult;
    }
  }

  componentDidMount() {
    console.log("index.js componentDidMount");
    AppState.addEventListener('change', this._handleAppStateChange);
    // ScannerManager.startSession()
    if(Platform.OS === 'ios'){
      setTimeout(()=>{
        console.log("aaa  ee index.js startSession");
        ScannerManager.startSession()
      },50);
    }
  }

  componentWillUnmount() {
    console.log("index.js componentWillUnmount");
    AppState.removeEventListener('change', this._handleAppStateChange);
    this.stopScan();
  }

  render() {
    return (
      <NativeBarCode
        {...this.props}
        onIDScannerResult={this._onIDScannerResult}
      />
    )
  }

  startScan() {
    console.log("aaa index.js startSession");
    ScannerManager.startSession()
  }

  stopScan() {
    console.log("aaa index.js stopSession");
    ScannerManager.stopSession()
  }

  restartScanner(){
    ScannerManager.restartScanner();
  }

  startRegByBtn(){
    ScannerManager.setCanReg();
  }

  //todo
  recogFromFile(file='file'){
    ScannerManager.IDCardRecognitFromFile('file',(res)=>{
      alert(res);
    })
  }



  _handleAppStateChange = (currentAppState) => {
    if(currentAppState !== 'active' ) {
      this.stopScan()
    }
    else {
      this.startScan()
    }
  }
}

const NativeBarCode = requireNativeComponent(Platform.OS === 'ios' ? 'RCTIDCardScanner' : 'RCTScannerView', Scanner);