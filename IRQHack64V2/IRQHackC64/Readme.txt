IRQHack64 Kaynak kodlarý için açýklama
- Mayýs 2016 / I.R.on

Arduino klasöründe kullanýlan SdFat kütüphanesi ve IRQHack64 sketch'i mevcut. Sketch Arduino'nun þu an en son sürümü olan 1.6.8 sürümü ile test edildi (1.6.3 ile geliþtirildi). Arduino sketch'i içindeki FlashLib.h dosyasý C64'e gönderilen menü programýnýn binary'sini içeriyor. Menünün kaynak kodlarý deðiþtirilip yenisi üretildiðinde bu da deðiþtirilmeli. 


Tools klasöründe menü ve loader'ýn oluþturulmasý için gerekli araçlarýn bir bölümü ve IrqHackSend seri porttan program gönderme tool'u mevcut.
- Bin2ArdH.exe - Binary dosyayý C header'ý haline dönüþtüren bir program. Benzer programlardan farký oluþturulan diziyi PROGMEM olarak iþaretlemesi, böylece dizinin sadece flash'ta saklanmasý saðlanýyor.
- CreateEpromLoader.exe - 64IRQTransferSoftNewForC64Fast.65s'den üretilen 256 byte'lýk esas loader'ý 256 defa duplike eden program. 
Örn. Kullaným þekli : CreateEpromLoader.exe infile outfile 160 191
Burada 160 ve 191 loader içinde 0'dan 255'e kadar sayýlarla deðiþtirilmesi gereken pozisyonlarý ifade ediyor.
- IRQHackSend.exe - C64'e pc üstünden seri baðlantý ile program göndermeye yarayan örnek program. Pc ile IRQHack64 arasýnda seri baðlantý saðlandýktan sonra örnek olarak aþaðýdaki gibi kullanýlabilir. Kullanýlan baud rate : 57600
IRQHackSend.exe commando.prg COM3

C64 klasöründe menü ve loader'ýn source'larý mevcut,
Dosyalarýn açýklamalarý þu þekilde,

- IRQLoader.65s - IRQHack64 üzerinde bulunan eprom'da çalýþan loader'ýn kaynak kodu.
- LoaderStub.65s - Yükleme yapýldýktan sonra kaset buffer'ýna atýlan yüklenen programý çalýþtýran kýsým.
- IrqLoaderMenuNew.65s - IRQHack64 sketch'ine gömülen c64 menüsünün kaynak kodu.
- IrqLoaderMenu.bas - Menünün baþýna eklenen basic önyükleyici satýrý
- avrincludehead.txt - Flashlib.h'ý oluþturan ilk kýsým
- avrincludefoot.txt - Flashlib.h'ý oluþturan son kýsým
- Build - I_R_on.bat veya Build - Wizofwor.bat - Loader ve menüyü oluþturmak için kullanýlan batch dosya. C64 kodunu derleyebilmek için path üstünde 64tass ve petcat (vice ile beraber geliyor) programlarý olmalý.
Batch dosya çalýþtýðýnda temel olarak 3 adet çýktý üretiyor
- PreBuild.bat, PostBuild.bat - üstteki iki ayrý menü için baþta ve sonda ortak kullanýlan iþlemler
- irqhack64.prg - Build sonrasý sd kart'a atýlmasý gereken menü dosyasý
- Flashlib.h - Arduino sketch'i içine aktarýlacak kodun c header'ý haline getirilmiþ hali.
- IRQLoaderRom.bin - 27C512 Eprom'a yazýlacak loader. 