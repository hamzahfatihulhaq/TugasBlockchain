// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract Purchase {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive }
    // Variabel status memiliki nilai default dari anggota pertama, `State.created`
    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    /// Hanya pembeli yang dapat memanggil fungsi ini.
    error OnlyBuyer();
    /// Hanya penjual yang dapat memanggil fungsi ini.
    error OnlySeller();
    /// Fungsi tidak dapat dipanggil pada kondisi saat ini.
    error InvalidState();
    /// Nilai yang diberikan harus genap.
    error ValueNotEven();

    modifier onlyBuyer() {
        if (msg.sender != buyer)
            revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller)
            revert OnlySeller();
        _;
    }

    modifier inState(State state_) {
        if (state != state_)
            revert InvalidState();
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    // Pastikan `msg.value` adalah bilangan genap.
    // Pembagian akan terpotong jika bilangan ganjil.
    // Periksa melalui perkalian bahwa itu bukan bilangan ganjil.
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value)
            revert ValueNotEven();
    }

    /// Batalkan pembelian dan dapatkan kembali eter.
    /// Hanya dapat dipanggil oleh penjual sebelum
    /// kontrak dikunci.
    function abort()
        external
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        // Kami menggunakan transfer di sini secara langsung.
        // Ini aman untuk masuk kembali, karena ini adalah 
        // panggilan terakhir dalam fungsi ini dan kami
        // telah mengubah statusnya.
        seller.transfer(address(this).balance);
    }

    /// Konfirmasi pembelian sebagai pembeli.
    /// Transaksi harus menyertakan `2 * nilai` eter.
    /// Eter akan dikunci sampai confirmReceived
    /// dipanggil.
    function confirmPurchase()
        external
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    /// Konfirmasikan bahwa Anda (pembeli) telah menerima barang tersebut.
    /// Ini akan melepaskan eter yang terkunci.
    function confirmReceived()
        external
        onlyBuyer
        inState(State.Locked)
    {
        emit ItemReceived();
        // Penting untuk mengubah status terlebih dahulu karena
        // jika tidak, kontrak yang dipanggil menggunakan `kirim` di bawah ini
        // dapat dipanggil lagi di sini.
        state = State.Release;

        buyer.transfer(value);
    }

    /// Fungsi ini mengembalikan uang penjual, mis.
    /// membayar kembali dana yang terkunci dari penjual.
    function refundSeller()
        external
        onlySeller
        inState(State.Release)
    {
        emit SellerRefunded();
        // Penting untuk mengubah status terlebih dahulu karena
        // jika tidak, kontrak yang dipanggil menggunakan `kirim` di bawah ini
        // dapat dipanggil lagi di sini.
        state = State.Inactive;

        seller.transfer(3 * value);
    }
}