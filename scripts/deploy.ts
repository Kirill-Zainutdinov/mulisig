import { ethers } from "hardhat"

async function main() {
    
    const admins = await ethers.getSigners()
    const Multisig = await ethers.getContractFactory("Multisig")
    const multisig = await Multisig.deploy([admins[0].address, admins[1].address, admins[2].address])
    await multisig.deployed()

    const Target = await ethers.getContractFactory("Target")
    const target = await Target.deploy()
    await target.deployed()

    console.log("deployed")

    // получаем интерфейс нужной функции
    const iface = new ethers.utils.Interface(['function setNumber(uint256)'])
    // собираем для неё calldata
    const payload = iface.encodeFunctionData("setNumber", [100])
    // console.log("address: ", target.address)
    // console.log("calldata: ", calldata)

    // получаем nonce
    const nonce = await multisig.nonce()
    // создаём кодер
    const abiCoder = ethers.utils.defaultAbiCoder

    // const message = ethers.utils.arrayify(ethers.utils.keccak256(ethers.utils.solidityPack(
    //     [ "uint256", "address", "address", "bytes" ],
    //     [ nonce, verify.address, target.address, payload ]
    // )))

    const message = ethers.utils.arrayify(ethers.utils.solidityPack(
        [ "uint256", "address", "address", "bytes" ],
        [ nonce, multisig.address, target.address, payload ]
    ))

    console.log("message:\n", message)
    console.log("message.length: ", message.length)
    
    // получаем хеш сообщения - это именно та штуку, которая подписывается функцией signMessage()
    const hashMessage = ethers.utils.hashMessage(message)
    console.log("hashMessage: ", hashMessage)

    let signatures: {
        v: number[],
        r: string[],
        s: string[]
    }

    signatures = {
        v: [],
        r: [],
        s: []
    }
    for(let i = 0; i < 3; i++){
        let powSignature = await admins[i].signMessage(message)
        let signature = ethers.utils.splitSignature(powSignature)
        signatures.v.push(signature.v)
        signatures.r.push(signature.r)
        signatures.s.push(signature.s)
    }
    // console.log(signatures)


    await multisig.verify(nonce, target.address, payload, signatures.v, signatures.r, signatures.s)

    console.log(await target.number())
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
