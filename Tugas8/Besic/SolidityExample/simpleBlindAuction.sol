// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract SimpleAuction {
    // Parameter lelang. Waktu adalah cap
    // waktu unix absolut (detik sejak 1970-01-01)
    // atau periode waktu dalam detik.
    address payable public beneficiary;
    uint public auctionEndTime;

    // Kondisi lelang saat ini.
    address public highestBidder;
    uint public highestBid;

    // Penarikan yang diizinkan dari tawaran sebelumnya
    mapping(address => uint) pendingReturns;

    // Setel ke true di akhir, larang perubahan apa pun.
    // Secara default diinisialisasi ke `false`.
    bool ended;

    // Peristiwa yang akan dipancarkan pada perubahan.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Error yang menjelaskan kegagalan.

    // Komentar triple-slash disebut komentar natspec.
    // Mereka akan ditampilkan ketika pengguna
    // diminta untuk mengkonfirmasi transaksi atau
    // ketika kesalahan ditampilkan.

    /// Lelang sudah berakhir.
    error AuctionAlreadyEnded();
    /// Sudah ada tawaran yang lebih tinggi atau sama.
    error BidNotHighEnough(uint highestBid);
    /// Pelelangan belum berakhir.
    error AuctionNotYetEnded();
    /// Fungsi AuctionEnd telah dipanggil.
    error AuctionEndAlreadyCalled();

    /// Buat lelang sederhana dengan `biddingTime` 
    /// detik waktu penawaran atas nama alamat 
    /// penerima `beneficiaryAddress`.
    constructor(
        uint biddingTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    /// Bid pada lelang dengan nilai yang dikirimkan 
    /// bersama dengan transaksi ini.
    /// Nilai tersebut hanya akan dikembalikan jika
    /// lelang tidak dimenangkan.
    function bid() external payable {
        // Tidak ada argumen yang diperlukan, semua
        // informasi sudah menjadi bagian
        // dari transaksi. Hutang kata kunci diperlukan
        // agar fungsi dapat
        // bmenerima Eter.

        // Kembalikan panggilan jika
        // periode penawaran berakhir.
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();

        // Jika tawaran tidak lebih tinggi, kirim
        // uang kembali (pernyataan pengembalian
        // akan mengembalikan semua perubahan
        // dalam pelaksanaan fungsi ini termasuk
        // etelah menerima uang).
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            // Mengirim kembali uang hanya dengan menggunakan
            // HighBidder.send(highestBid) adalah risiko keamanan
            // karena dapat mengeksekusi kontrak yang tidak tepercaya.
            // Itu selalu lebih aman untuk membiarkan penerima
            // menarik uang mereka sendiri.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Tarik tawaran yang overbid.
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Penting untuk menyetel ini ke nol karena penerima
            // dapat memanggil fungsi ini lagi sebagai bagian dari panggilan penerima
            // sebelum `send` kembali.
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // Tidak perlu menelepon lempar di sini, cukup setel ulang jumlah yang harus dibayar
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// Akhiri lelang dan kirimkan penawaran tertinggi
    /// ke penerima.
    function auctionEnd() external {
        // Ini adalah pedoman yang baik untuk struktur fungsi yang berinteraksi 
        // dengan kontrak lain (yaitu mereka memanggil fungsi atau mengirim Eter)
        // menjadi tiga fase:
        // 1. memeriksa kondisi
        // 2. melakukan tindakan (kondisi yang berpotensi berubah)
        // 3. berinteraksi dengan kontrak lain
        /*
        Jika fase-fase ini tercampur, kontrak lain dapat 
        memanggil kembali ke kontrak saat ini dan mengubah 
        status atau menyebabkan efek (pembayaran eter) 
        dilakukan beberapa kali. Jika fungsi yang disebut 
        secara internal mencakup interaksi dengan kontrak 
        eksternal, mereka juga harus dianggap sebagai 
        interaksi dengan kontrak eksternal.
        */
        // 1. Conditions
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}