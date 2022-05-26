// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Coin {
    // Kata kunci "publik" membuat variabel
    // dapat diakses dari kontrak lain
    /*
        Jenis alamat adalah nilai 160-bit 
        yang tidak memungkinkan operasi aritmatika 
        apa pun. Sangat cocok untuk menyimpan alamat 
        kontrak, atau hash dari setengah publik 
        keypair milik akun eksternal.
    */
    address public minter; 
    mapping (address => uint) public balances;

    // Event memungkinkan klien untuk bereaksi terhadap spesifik
    // perubahan kontrak yang Anda nyatakan
    event Sent(address from, address to, uint amount);

    //Kode konstruktor hanya dijalankan ketika 
    //kontrak dibuat
    constructor() {
        minter = msg.sender;
    }

    // Mengirim sejumlah koin yang baru dibuat ke alamat
    // Hanya dapat dipanggil oleh pembuat kontrak
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    // Kesalahan atau error memungkinkan Anda memberikan informasi tentang
    // mengapa suatu operasi gagal. Mereka dikembalikan
    // ke pemanggil fungsi.
    error InsufficientBalance(uint requested, uint available);

    // Mengirim sejumlah koin yang ada
    // dari penelepon mana pun ke alamat
    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}