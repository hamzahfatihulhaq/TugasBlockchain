// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    // Penarikan yang diizinkan dari tawaran sebelumnya
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    // Kesalahan yang menggambarkan kegagalan.

    /// Fungsi telah dipanggil terlalu dini. 
    /// Coba lagi pada `time`.
    error TooEarly(uint time);
    /// Fungsi telah dipanggil terlambat.
    /// Itu tidak dapat dipanggil setelah `time`.
    error TooLate(uint time);
    /// Fungsi AuctionEnd telah dipanggil.
    error AuctionEndAlreadyCalled();

    // Modifiers adalah cara mudah untuk memvalidasi input
    // ke fungsi. `onlyBefore` diterapkan pada `bid` di bawah ini:
    // Badan fungsi baru adalah badan pengubah di mana
    // `_` diganti dengan badan fungsi lama.
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    constructor(
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
    }

    /// Tempatkan tawaran buta dengan `blindedBid` =
    /// keccak256(abi.encodePacked(value, fake, secret)).
    /// Eter yang dikirim hanya dikembalikan jika tawaran 
    /// diungkapkan dengan benar fase pengungkapan. Tawaran valid jika
    /// ter yang dikirim bersama dengan tawaran setidaknya "nilai" dan 
    /// "palsu" tidak benar. Mengatur "palsu" menjadi benar dan mengirimkan
    /// bukan jumlah yang tepat adalah cara untuk menyembunyikan tawaran nyata tetapi
    /// tetap melakukan setoran yang diperlukan. Alamat yang sama dapat 
    /// mengajukan beberapa tawaran.
    function bid(bytes32 blindedBid)
        external
        payable
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: blindedBid,
            deposit: msg.value
        }));
    }

    /// Ungkapkan tawaran buta Anda. Anda akan mendapatkan pengembalian dana untuk semua
    /// tawaran tidak valid yang dibutakan dengan benar dan untuk 
    /// semua tawaran kecuali yang benar-benar tertinggi.
    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    )
        external
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(values.length == length);
        require(fakes.length == length);
        require(secrets.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) =
                    (values[i], fakes[i], secrets[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                // Tawaran sebenarnya tidak terungkap.
                // Jangan mengembalikan uang deposit.
                continue;
            }
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            // Membuat tidak mungkin bagi pengirim untuk mengklaim kembali
            // deposit yang sama.
            bidToCheck.blindedBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }

    /// Tarik tawaran yang overbid.
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Penting untuk menyetel ini ke nol karena penerima
            // dapat memanggil fungsi ini lagi sebagai bagian dari panggilan penerima
            // sebelum `transfer` kembali (lihat komentar di atas tentang
            // conditions -> effects -> interaction).
            pendingReturns[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }

    /// Akhiri lelang dan kirimkan penawaran tertinggi
    /// ke beneficiary.
    function auctionEnd()
        external
        onlyAfter(revealEnd)
    {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }

    // Ini adalah fungsi "internal" yang berarti hanya 
    // dapat dipanggil dari kontrak itu sendiri (atau dari 
    // derived contracts).
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // Pengembalian dana penawar tertinggi sebelumnya.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}