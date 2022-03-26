// Copyright 2017 The go-ethereum Authors
// This file is part of the go-ethereum library.
//
// The go-ethereum library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-ethereum library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

// Package consensus implements different Ethereum consensus engines.
package consensus //me : mengambil file sumber dalam direktori consensus  untuk mengimplementasikan mesin konsensus ethereum yang berbeda

import ( // me : mengimport file 
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/params"
	"github.com/ethereum/go-ethereum/rpc"
)

// ChainHeaderReader defines a small collection of methods needed to access the local
// blockchain during header verification.
// me : chainHeaderReader mendefinisikan kumpulan kecil metode yang diperlukan untuk mengakses local
// me : blockchain selama verifikasi header
type ChainHeaderReader interface {  // me : interface tipe yang digunakan untuk menentukan satu atau lebih tanda tangan metode dan antarmuka bersifat abstrak
	// Config retrieves the blockchain's chain configuration.
	Config() *params.ChainConfig // me : untuk mengambil konfigurasi rantai blockhain

	// CurrentHeader retrieves the current header from the local chain.
	CurrentHeader() *types.Header // me : untuk mengambil header saat ini dari rantai lokal

	// GetHeader retrieves a block header from the database by hash and number.
	GetHeader(hash common.Hash, number uint64) *types.Header // me : untuk mengambil header blok dari database dengan hash dan nomor

	// GetHeaderByNumber retrieves a block header from the database by number.
	GetHeaderByNumber(number uint64) *types.Header // me : untuk mengambil header blok dari database dengan nomor

	// GetHeaderByHash retrieves a block header from the database by its hash.
	GetHeaderByHash(hash common.Hash) *types.Header // me : untuk mengambil header blok dari database dengan hash-nya

	// GetTd retrieves the total difficulty from the database by hash and number.
	GetTd(hash common.Hash, number uint64) *big.Int // me : untuk mengambil total kesulitan dari database dengan hash dan nomor
}

// ChainReader defines a small collection of methods needed to access the local
// blockchain during header and/or uncle verification.
// me : chainReader mendefinisikan kumpulan kecil metode yang diperlukan untuk mengakses lokal
// me : blockchain selama verifikasi header dan atau uncle
type ChainReader interface {
	ChainHeaderReader

	// GetBlock retrieves a block from the database by hash and number.
	GetBlock(hash common.Hash, number uint64) *types.Block // me : Getblok mengambil blok dari database dengan hash dan nomor
}

// Engine is an algorithm agnostic consensus engine.
// me : engine fungsi yang menggunakan konsensus agnastik algoritma
type Engine interface {
	// Author retrieves the Ethereum address of the account that minted the given
	// block, which may be different from the header's coinbase if a consensus
	// engine is based on signatures.
	
	/* me : Author/penulis mengambil alamat etheruem dari akun yang tercetak block yang 
			diberikan, yang memungkin berbeda dari basis koin header jika konsensus
			engine berdasarkan pada signatures */
	Author(header *types.Header) (common.Address, error)

	// VerifyHeader checks whether a header conforms to the consensus rules of a
	// given engine. Verifying the seal may be done optionally here, or explicitly
	// via the VerifySeal method.
	
	/* me : verifyHeader memeriksa apakah header sesuai dengan aturan konsensus dari
			mesin yang diberikan . memverifikasikan segel dapat dilakukan secara opsional
			disini, atau secara eksplesit melalui metode VerifySeal */
	VerifyHeader(chain ChainHeaderReader, header *types.Header, seal bool) error

	// VerifyHeaders is similar to VerifyHeader, but verifies a batch of headers
	// concurrently. The method returns a quit channel to abort the operations and
	// a results channel to retrieve the async verifications (the order is that of
	// the input slice).
	
	/* me : verifyHeader mirip dengan verifyHeader, tetapi verifyHeader memverifikasi 
			sekumpulan header secara bersamaan. metode ini mengembalikan saluran keluar
			untuk membatalkan operasi dan saluran hasil untuk mengambil verifikasi asinkron
			(urutan adalah urutan irisan input)*/
	VerifyHeaders(chain ChainHeaderReader, headers []*types.Header, seals []bool) (chan<- struct{}, <-chan error)

	// VerifyUncles verifies that the given block's uncles conform to the consensus
	// rules of a given engine.
	
	/* me : VerifyUncles memverifikasikan bahwa blok paman yang diberikan sesuai dengan 
			aturan konsensus dari mesin yang diberikan. */
	VerifyUncles(chain ChainReader, block *types.Block) error

	// Prepare initializes the consensus fields of a block header according to the
	// rules of a particular engine. The changes are executed inline.
	
	/* me : mempersiapkan penginisialisasian bidang konsensus dari header blok sesuai 
			dengan aturan engine tertentu. perubahan dijalankan inline*/
	Prepare(chain ChainHeaderReader, header *types.Header) error

	// Finalize runs any post-transaction state modifications (e.g. block rewards)
	// but does not assemble the block.
	
	// Note: The block header and state database might be updated to reflect any
	// consensus rules that happen at finalization (e.g. block rewards).

	// me  : Finalize menjalankan modifikasi status pasca transaksi apapun (misalnya block rewards) tetapi tidak merakit blok
	Finalize(chain ChainHeaderReader, header *types.Header, state *state.StateDB, txs []*types.Transaction,
		uncles []*types.Header)

	// FinalizeAndAssemble runs any post-transaction state modifications (e.g. block
	// rewards) and assembles the final block.
	//
	// Note: The block header and state database might be updated to reflect any
	// consensus rules that happen at finalization (e.g. block rewards).

	/* me : FinalizeAndAssemble menjalankan modifikasi status pasca-transaksi (misal
			nya. block rewards) dan assembles the final block*/
	FinalizeAndAssemble(chain ChainHeaderReader, header *types.Header, state *state.StateDB, txs []*types.Transaction,
		uncles []*types.Header, receipts []*types.Receipt) (*types.Block, error)

	// Seal generates a new sealing request for the given input block and pushes
	// the result into the given channel.
	//
	// Note, the method returns immediately and will send the result async. More
	// than one result may also be returned depending on the consensus algorithm.

	/* me : seal menghasilkan permintaan penyegelan baru untuk blok input yang
			diberikan dan mendorong hasilnya ke saluran yang diberikan.*/
	Seal(chain ChainHeaderReader, block *types.Block, results chan<- *types.Block, stop <-chan struct{}) error

	// SealHash returns the hash of a block prior to it being sealed.
	SealHash(header *types.Header) common.Hash // me : sealHash mengembalikan hash dari sebuah block sebelum disegel

	// CalcDifficulty is the difficulty adjustment algorithm. It returns the difficulty
	// that a new block should have.

	/* me : CalcDifficulty mengembalikan hash dari sebuah blok sebelum disegel. 
			CalcDifficulty adalah algoritma penyesuaian tingkat kesulitan. 
			ini mengembalikan kesulitan yang seharusnya dimiliki block baru. */
	CalcDifficulty(chain ChainHeaderReader, time uint64, parent *types.Header) *big.Int

	// APIs returns the RPC APIs this consensus engine provides.
	// me : APIs mengembalikan API RPC yang disediakan mesin konsensus ini
	APIs(chain ChainHeaderReader) []rpc.API

	// Close terminates any background threads maintained by the consensus engine.
	// me : tutup mengakhiri semua utas latar belakang yang dikelola oleh mesin konsensus
	Close() error
}

// PoW is a consensus engine based on proof-of-work.
// me : PoW adalah consensus engine berdasrakan buktik kerja(proof-of-work)
type PoW interface {
	Engine

	// Hashrate returns the current mining hashrate of a PoW consensus engine.
	// me : Hashrate mengembalikan hashrate penambangan saat ini dari mesin konsensus PoW. 
	Hashrate() float64
}
