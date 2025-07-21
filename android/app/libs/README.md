# Samsung Health Data SDK Kurulum Talimatları

## İndirme Adımları:

1. Samsung Developer sitesine gidin: https://developer.samsung.com/health/data/overview.html
2. "Samsung Health Data SDK v1.0.0 beta2 (8.8 MB)" butonuna tıklayın
3. İndirilen ZIP dosyasını açın

## Dosya Yapısı:
```
samsung-health-data-sdk-v1.0.0-beta2/
├── docs/           # API Reference ve Programming Guide  
├── libs/           # AAR dosyaları buradan alınacak
├── samples/        # Örnek uygulamalar
└── tools/          # Test araçları
```

## Yapılacaklar:

1. **libs/samsung-health-data-v1.0.0-beta2.aar** dosyasını bu klasöre kopyalayın
2. Eğer başka dependency AAR dosyaları varsa onları da ekleyin

## Sonraki Adım:
AAR dosyaları eklendikten sonra `android/app/build.gradle` güncellenecek.

**Not:** Bu SDK **emulator desteklemiyor** - sadece gerçek Samsung cihazlarda çalışır. 