import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/random_call_service.dart';

class AurenRandomCallScreen extends StatefulWidget{
 final String callId; final bool caller; final String kind; final String otherName;
 const AurenRandomCallScreen({super.key,required this.callId,required this.caller,required this.kind,this.otherName='AUREN User'});
 @override State<AurenRandomCallScreen> createState()=>_AurenRandomCallScreenState();
}
class _AurenRandomCallScreenState extends State<AurenRandomCallScreen>{
 final auth=FirebaseAurenAuthService(); final service=AurenRandomCallService();
 final local=RTCVideoRenderer(),remote=RTCVideoRenderer(); RTCPeerConnection? pc; MediaStream? stream; bool muted=false,cameraOff=false,ready=false; String state='connecting';
 @override void initState(){super.initState();_start();}
 Future<void> _start()async{await local.initialize();await remote.initialize();final uid=auth.currentUserId;if(uid==null)return;pc=await createPeerConnection({'iceServers':[{'urls':'stun:stun.l.google.com:19302'}]});pc!.onTrack=(e){if(e.streams.isNotEmpty){remote.srcObject=e.streams.first;setState(()=>state='connected');}};pc!.onConnectionState=(s){if(mounted)setState(()=>state=s.toString().split('.').last);};final isVideo=widget.kind=='video';stream=await navigator.mediaDevices.getUserMedia({'audio':true,'video':isVideo});for(final t in stream!.getTracks()){await pc!.addTrack(t,stream!);}if(widget.caller){final offer=await pc!.createOffer();await pc!.setLocalDescription(offer);final d=await pc!.getLocalDescription();await service.db.collection('random_calls').doc(widget.callId).update({'offer':{'sdp':d?.sdp,'type':d?.type}});}else{await _answer();}setState(()=>ready=true);}
 Future<void> _answer()async{final snap=await service.db.collection('random_calls').doc(widget.callId).get();final o=snap.data()?['offer'];if(o==null)return;await pc!.setRemoteDescription(RTCSessionDescription(o['sdp'],o['type']));final a=await pc!.createAnswer();await pc!.setLocalDescription(a);final d=await pc!.getLocalDescription();await service.answer(widget.callId,{'sdp':d?.sdp,'type':d?.type});}
 Future<void> _hang(){return service.end(widget.callId,auth.currentUserId??'unknown').then((_){Navigator.of(context).pop();});}
 @override void dispose(){stream?.getTracks().forEach((t)=>t.stop());stream?.dispose();pc?.close();local.dispose();remote.dispose();super.dispose();}
 @override Widget build(BuildContext c){return Scaffold(backgroundColor:Colors.black,appBar:AppBar(title:Text(widget.otherName)),body:Stack(children:[Positioned.fill(child:widget.kind=='video'?RTCVideoView(remote,objectFit:RTCVideoViewObjectFit.RTCVideoViewObjectFitCover):const Center(child:Icon(Icons.person,color:Colors.white,size:100))),if(widget.kind=='video')Positioned(right:16,top:16,width:110,height:160,child:RTCVideoView(local,mirror:true)),Positioned(bottom:24,left:16,right:16,child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[IconButton(onPressed:()=>setState((){muted=!muted;stream?.getAudioTracks().forEach((t)=>t.enabled=!muted);}),icon:Icon(muted?Icons.mic_off:Icons.mic,color:Colors.white)),IconButton(onPressed:_hang,icon:const Icon(Icons.call_end,color:Colors.red,size:38)),if(widget.kind=='video')IconButton(onPressed:()=>setState((){cameraOff=!cameraOff;stream?.getVideoTracks().forEach((t)=>t.enabled=!cameraOff);}),icon:Icon(cameraOff?Icons.videocam_off:Icons.videocam,color:Colors.white))]),),if(!ready)const Center(child:CircularProgressIndicator())]));}
}