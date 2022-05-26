// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.
contract Ballot {
    // Ini mendeklarasikan tipe kompleks baru yang akan
    // digunakan untuk variabel nanti.
    // Ini akan mewakili pemilih tunggal.
    struct Voter {
        uint weight; // berat diakumulasikan oleh delegasi
        bool voted;  // jika benar, orang tersebut sudah memilih
        address delegate; // orang yang didelegasikan kepada
        uint vote;   // indeks dari proposal terpilih
    }

    // Ini adalah jenis untuk proposal tunggal.
    struct Proposal {
        bytes32 name;   // nama pendek (hingga 32 byte)
        uint voteCount; // jumlah suara yang terkumpul
    }

    address public chairperson;

    // Ini mendeklarasikan variabel status yang
    // menyimpan struct `Voter` untuk setiap alamat yang memungkinkan.
    mapping(address => Voter) public voters;

    // Array struct `Proposal` berukuran dinamis.
    Proposal[] public proposals;

    /// Buat surat suara baru untuk memilih salah satu `proposalNames`.
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // Untuk setiap nama proposal yang disediakan,
        // buat objek proposal baru dan tambahkan
        // ke akhir array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` membuat sementara
            // Proposal object dan `proposals.push(...)`
            // menambahkannya ke akhir `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Beri `voter` hak untuk memberikan suara pada surat suara ini. 
    // Hanya dapat dipanggil oleh `chairperson`.
    function giveRightToVote(address voter) external {
        // Jika argumen pertama dari `require` dievaluasi 
        // menjadi `false`, eksekusi dihentikan dan semua
        // perubahan pada status dan keseimbangan Eter 
        // dikembalikan.
        // Ini digunakan untuk mengkonsumsi semua gas dalam versi EVM lama, 
        // tetapi sekarang tidak lagi.
        // Sering kali merupakan ide yang baik untuk menggunakan `require` untuk memeriksa
        // apakah fungsi dipanggil dengan benar.
        // Sebagai argumen kedua, Anda juga dapat memberikan
        // penjelasan tentang apa yang salah.
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegasikan suara Anda kepada pemilih (voter) `to`.
    function delegate(address to) external {
        // memberikan referensi
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        // Teruskan delegasi selama
        // `to` juga didelegasikan.
        // Secara umum, loop seperti itu sangat berbahaya,
        // karena jika berjalan terlalu lama, mereka mungkin
        // membutuhkan lebih banyak gas daripada yang tersedia dalam satu blok.
        // Dalam hal ini, delegasi tidak akan dieksekusi, 
        // tetapi dalam situasi lain, pengulangan seperti itu 
        // dapat menyebabkan kontrak "stuck" sepenuhnya.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // Kami menemukan loop dalam delegasi, tidak diizinkan.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Karena `sender` adalah referensi, ini
        // memodifikasi `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // Jika delegasi sudah memilih, 
            // langsung tambahkan jumlah suara
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // Jika delegasi belum memilih,
            // tambahkan bobotnya.
            delegate_.weight += sender.weight;
        }
    }

    /// Berikan suara Anda (termasuk suara yang didelegasikan kepada Anda)
    /// ke `proposals[proposal].name` proposal.
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        // Jika `proposal` berada di luar jangkauan array,
        // ini akan membuang secara otomatis dan mengembalikan semua perubahan.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Menghitung proposal pemenang dengan mempertimbangkan
    /// semua suara sebelumnya.
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Memanggil fungsi WinProposal() untuk mendapatkan indeks
    // pemenang yang terdapat dalam array proposal dan kemudian 
    // mengembalikan nama pemenang
    function winnerName() external view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}