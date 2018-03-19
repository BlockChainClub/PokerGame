pragma solidity ~0.4.20;

//定义不等价代币交换合约接口和事件
/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract SuperDharmaCardBase {	
    event Create(address owner, uint256 cardId, uint256 genes);
	event Transfer(address from, address to, uint256 tokenId);
    event DebugStr(string str);
	
	struct SuperDharmaCard {
		uint256 genes;      //达摩卡牌的基因
		
		string nickName;    //用户名
		string RoleImgURL;  //用户形象
		string wechatID;    //微信ID
		
		//学科分数mapping
		mapping ( uint => uint ) mapSubjectGoal; 
	}
	
	SuperDharmaCard[] public superDharmaCards;
	
	//达摩卡的拥有者
	mapping (uint256 => address) superDharmaCardIndexToOwner;	
	       
    //地址拥有卡牌的个数
    mapping (address => uint256) ownershipTokenCount;  
	
	//卡牌操作许可
    mapping (uint256 => address) public superDharmaIndexToApproved;
	
	
	 /// @dev Assigns ownership of a specific card to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal  {
        // Since the number of cards is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        superDharmaCardIndexToOwner[_tokenId] = _to;
        // When creating new card _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }
	
	function _createSuperDharmaCard(
        string _nickName,
        string _RoleImgURL,
        string _wechatID,
        uint[] _subject,
        uint256[] _goal,
        uint256 _genes,
        address _owner
    )
        public
        returns (uint)
    {
        DebugStr("in _createSuperDharmaCard");
        
        SuperDharmaCard memory _card = SuperDharmaCard({
            genes: _genes,
            nickName: _nickName,
            RoleImgURL: _RoleImgURL,
            wechatID: _wechatID
        });

        
        DebugStr("create  Kitty");
        uint256 newCardId = superDharmaCards.push(_card) - 1;
        
       //写入学科排名信息
       for(uint i =0; i< _subject.length; i++) {
            if(i < _goal.length) {
                superDharmaCards[newCardId].mapSubjectGoal[ _subject[i] ] = _goal[i];
            }
            else
            {
                break;
            }
        }
        
        // It's probably never going to happen, 4 billion cats is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newCardId == uint256(uint32(newCardId)));
        // emit the birth event
        Create(
            _owner,
            newCardId,
            _card.genes
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newCardId);
        DebugStr("transfe  ok!!!");
        return newCardId;
    }
	
}	


contract GeneScienceInterface {
    event DebugStr(string str);
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() public pure returns (bool){
        return true;
    }
	
    function toBytesEth(uint256 x) private pure returns (uint8[32] b) {
        for (uint i = 0; i < 32; i++) {
            b[i] = uint8(x / (2**(8*(31 - i))));
        }
    }
    function bytesToUint256(uint8[32] b) private pure returns (uint256) {
        uint256 out;
        for (uint i = 0; i < 32; i++) {
            out |= (uint256(b[i] & 0xFF) << (i * 8));
        }
        return out;
    }    
    
    function uintToString(uint v) private pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s);  // memory isn't implicitly convertible to storage
        return str; // this was missing
    }
    // 简单混合规则，
    //  混合基因
    /// @dev given genes of card 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2) public view returns (uint256){
        //简单版随机混合
        uint8[32] memory b1 = toBytesEth(genes1);
        uint8[32] memory b2 = toBytesEth(genes2);
            
        uint8[32] memory bRet;
        for (uint i = 0; i < 32; i++) {
            
            bRet[i] = (b1[i] + b2[i] ) %255;
            DebugStr(uintToString(b1[i]));
            DebugStr(uintToString(b2[i]));
            DebugStr(uintToString(bRet[i]));
        }
        uint256 out = bytesToUint256(bRet);
        return out;
    }
}





contract SuperDharmaCardCore is ERC721, SuperDharmaCardBase{
    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.
    //  设置达摩卡的拥有者
    /// @dev Checks if a given address is the current owner of a particular Dharma.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId card id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return superDharmaCardIndexToOwner[_tokenId] == _claimant;
    }
    //  设置达摩卡的操作者，可以把达摩卡发送给别人
    /// @dev Checks if a given address currently has transferApproval for a particular Dharma.
    /// @param _claimant the address we are confirming card is approved for.
    /// @param _tokenId card id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return superDharmaIndexToApproved[_tokenId] == _claimant;
    }
    //  设置达摩卡的操作者，可以把达摩卡发给别人
    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Kitties on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        superDharmaIndexToApproved[_tokenId] = _approved;
    }
    //  查看某个地址达摩卡的总量
    /// @notice Returns the number of Kitties owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }
    //  发送达摩卡给别人
    /// @notice Transfers a Dharma to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CryptoKitties specifically) or your Dharma may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Dharma to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any cards (except very briefly
        // after a gen0 card is created and before it goes on auction).
        require(_to != address(this));
        // You can only send your own card.
        require(_owns(msg.sender, _tokenId));
        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }
	
    // 设置某个达摩卡的掌控者地址
    /// @notice Grant another address the right to transfer a specific Dharma via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Dharma that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));
        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);
        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }
	
    //  达摩卡的发送函数
    /// @notice Transfer a Dharma owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Dharma to be transfered.
    /// @param _to The address that should take ownership of the Dharma. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Dharma to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any cards (except very briefly
        // after a gen0 card is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }
    //  查看当前达摩卡的个数
    /// @notice Returns the total number of cards currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return superDharmaCards.length - 1;
    }
	
    //  查看达摩卡的当前拥有者
    /// @notice Returns the address currently assigned ownership of a given Dharma.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = superDharmaCardIndexToOwner[_tokenId];
        require(owner != address(0));
    }
	
    // 查看某个地址的所有达摩卡ID
    /// @notice Returns a list of all Dharma IDs assigned to an address.
    /// @param _owner The owner whose cards we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Dharma array looking for cards belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = totalSupply();
            uint256 resultIndex = 0;
            // We count on the fact that all cards have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 cardId;
            for (cardId = 1; cardId <= totalCats; cardId++) {
                if (superDharmaCardIndexToOwner[cardId] == _owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
     function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return true;
    }
}

