import 'package:flutter/material.dart';
import '../../../core/models/product.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import 'product_detail_screen.dart';

class AurenSellerStorefrontScreen extends StatelessWidget {
  final String ownerId; final String title;
  const AurenSellerStorefrontScreen({super.key,required this.ownerId,this.title='متجري'});
  @override Widget build(BuildContext context){
    final repo=MarketplaceRepository();
    return Scaffold(appBar:AppBar(title:Text(title)),body:StreamBuilder<List<AurenProduct>>(stream:repo.watchByOwnerIds([ownerId]),builder:(context,s){
      if(s.hasError)return Center(child:Text('حدث خطأ: ${s.error}'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final items=s.data!;
      if(items.isEmpty)return const Center(child:Text('لا توجد منتجات منشورة بعد.'));
      final grouped=<String,List<AurenProduct>>{};
      for(final p in items){grouped.putIfAbsent(p.category,()=>[]).add(p);}
      return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,24),children:[
        Row(children:[const Icon(Icons.storefront,size:28),const SizedBox(width:8),Expanded(child:Text(title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold))),Text('${items.length} عنصر')]),
        const SizedBox(height:16),
        ...grouped.entries.map((entry)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(entry.key,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
          SizedBox(height:235,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:entry.value.length,separatorBuilder:(_,__)=>const SizedBox(width:12),itemBuilder:(context,i){
            final p=entry.value[i];
            return SizedBox(width:170,child:Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenProductDetailScreen(product:p))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Expanded(child:p.imageUrl.isEmpty?const Center(child:Icon(Icons.storefront_outlined,size:40)):Image.network(p.imageUrl,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined)))),
              Padding(padding:const EdgeInsets.fromLTRB(10,8,10,2),child:Text(p.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold))),
              Padding(padding:const EdgeInsets.fromLTRB(10,0,10,8),child:Text('${(p.priceMinor/100).toStringAsFixed(2)} ${p.currency}')),
            ])));
          })),
        ]))
      ]);
    }));
  }
}