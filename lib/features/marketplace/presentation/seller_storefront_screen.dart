import 'package:flutter/material.dart';
import '../../../core/models/product.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import 'product_detail_screen.dart';

class AurenSellerStorefrontScreen extends StatelessWidget {
  final String ownerId;
  final String title;
  const AurenSellerStorefrontScreen({super.key,required this.ownerId,this.title='متجري'});
  @override Widget build(BuildContext context){
    final repo=MarketplaceRepository();
    return Scaffold(appBar:AppBar(title:Text(title)),body:StreamBuilder<List<AurenProduct>>(stream:repo.watchByOwnerIds([ownerId]),builder:(context,s){
      if(s.hasError)return Center(child:Text('حدث خطأ: ${s.error}'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final items=s.data!;
      if(items.isEmpty)return const Center(child:Text('لا توجد منتجات منشورة بعد.'));
      return GridView.builder(padding:const EdgeInsets.all(16),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.72),itemCount:items.length,itemBuilder:(context,i){
        final p=items[i];
        return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenProductDetailScreen(product:p))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:p.imageUrl.isEmpty?const Center(child:Icon(Icons.storefront_outlined,size:44)):Image.network(p.imageUrl,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined)))),
          Padding(padding:const EdgeInsets.all(10),child:Text(p.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold))),
          Padding(padding:const EdgeInsets.fromLTRB(10,0,10,10),child:Text('${(p.priceMinor/100).toStringAsFixed(2)} ${p.currency}')),
        ])));
      });
    }));
  }
}
