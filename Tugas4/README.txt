=================================================================================================
ANALISIS
=================================================================================================

Analisis source code consensus.go dari https://github.com/ethereum/go-ethereum . 
Consensus.go merupakan consensus etherium yang dibuat dengan bahasa go language.  Dalam consensus.go terdapat 4 interface. 

Interface yang pertama adalah ChainHeaderReader. Interface ChainHeaderReader berfungsi untuk melakukan verifikasi header. 
Untuk melakukan verifikasi header diperlukan pengembilan header dari rantai lokal, dari database dengan nomor, 
dari database dengan hash dan mengambil total kesulitan dari database dengan hash dan nomor.

Interface yang kedua adalah ChainReader. Interface ChainReader berfungsi untuk melakukan blockchain selama verifikasi header dan/atau uncle. 
Didalam fungsi tersebut terdapat Getblok yang berfungsi mengambil blok dari database dengan hash dan nomor.

Interface yang ketiga adalah Engine. Interface Engine merupakan interface untuk melakukan consensus agnostic algoritma.  
Untuk melakukan Consensus agnostic algoritma, pertama author/penulis mengambil alamat ethereum dadri akun yang tercetak block yang diberikan, 
jika berbeda dari basis koin header maka consensus engine berdasarkan pada signature. 
Kedua, memeriksa apakah header sesuai dengan aturan consensus dari mesin yang diberikan dan memverifikasi segel yang dilakukan secara opsianal atau secara eksplesit. 
Ketiga, melakuakn verifikasi sekumpulan header secara bersamaan dan mengemalikan saluran keluaran untuk membatalkan operasi dan saluran hasil untuk mengambil verifikasi asinkron. 
Keempat, memverifikasi blok uncle yadn diberikan sesuai dengan aturan dari consensus atau tidak. 
Kelima, memperisapkan penginisialisasian bidang consensus dari header blok sesuai aturan engine tertentu. 
Keenam, memodifikasi status pasca transaksi tetapi tidak merakit blok. 
Ketujuh, menjalakan modifikasi status pasca transaksi dan menggambungkan final blok. 
Kedelapan, menghasilkan permintaan penyegelan baru untuk blok input yang diberikan dan mendorong hasilnya ke channel yang diberikan. 
Kesembilan, mengembalikan hash dari sebuah block sebelum disgel. 
Kesepuluh, melakukan penyesuaian tingkat kesulitan.
Dan terakhir, mengembalikan API RPC yang disediakan mesin consensus.

Interface yang terakhir adalah PoW. Interface PoW merupakan interface untuk melakukan consensus engine berdasarkan Proof-Of-Work yang mengartikan berdasarkan bukti kerja. 
Interface PoW ini memanggil interface engine serta mengembalikan hashrate penambangan saat ini dari mesin konsensus PoW.

Sehingga dapat dikatakan bahwa consensus.go masih menggunakan metode PoW berdasarkan bukti kerja. 
Proof-of-work adalah mekanisme yang memungkinkan jaringan Ethereum yang terdesentralisasi untuk mencapai konsensus, atau menyetujui hal-hal seperti saldo akun dan urutan transaksi. 
Algoritma PoW yang berdasarkan penetapkan kesulitan dan aturan untuk pekerjaan yang dilakukan penambang. PoW merupakan tindakan menambahkan blok yang valid ke rantai. 
Semakin banyak pekerja/penambang yang dilakukan, semakin panjang rantainya, dan semakin tinggi nomor bloknya, semakin yakin jaringan tersebut tentang keadaan saat ini.