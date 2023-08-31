# LastWish Plugin
LastWish is a secure plugin designed for unexpected situations (such as accidents) where the original owner is unable to perform actions on a Safe (a digital wallet with assets), either due to accidental death or incapacity. This plugin allows for the transfer of Safe ownership to a designated address, preventing the assets within the Safe from being permanently locked.

## Problem to solve
In the unfortunate event of the Safe owner's unexpected demise, LastWish enables the safe transfer of assets from the Safe to a designated inheritor, preventing the permanent lockup of assets within the Safe. Despite the constant pursuit of profit and exploration in the realm of cryptocurrency, the occurrence of accidents is often overlooked. These accidents can lead to the irreversible locking of assets within the Safe. This not only results in the permanent loss of the owner but also deprives their loved ones of the fruits of their labor. The LastWish Plugin aims to address this concern by providing a straightforward solution: even in the face of unexpected events, we can ensure that the assets we've worked hard to accumulate are passed on to our cherished ones. Moreover, LastWish facilitates this process without requiring the sharing of existing permissions with the inheritor, mitigating concerns about the inheritor absconding with the Safe's assets—addressing a real-world issue that is not uncommon.


## Features
- User-friendly and easy to comprehend
- Directly compatible with existing Safes, requiring no additional setup
- Supports both the original Safe Module architecture([LastWishModule.sol](./src/LastWishModule.sol)) and the new Safe Plugin architecture([LastWishPlugin.sol](./src/LastWishPlugin.sol))

## How to Use
1. The Safe owner can designate an inheritor and set a lockout period within the LastWish configuration.

2. In the unfortunate event that the Gnosis owner is unable to perform Safe operations due to unforeseen circumstances, the designated inheritor can initiate a transfer request for the Safe, which then enters a locked state for a specified duration.

3. Once the lockout period has elapsed, the inheritor can proceed to claim ownership of the Safe and gain the authority to operate it.

4. In cases where the inheritor's intentions are malicious, the Safe owner retains the ability to reject the transfer request during the lockout period.
Simultaneously, the inheritor's access rights will be revoked. It is advisable to employ [Forta](https://forta.org/) to monitor whether any inheritance requests have been initiated by the inheritor.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```


### Deploy

```shell
$ forge script --broadcast --rpc-url $RPC --private-key $PRIVATE_KEY --sig 'run(string)' script/DeployPlugin.s.sol:DeployAll $PATH_TO_JSON
```



## License

[MIT](https://choosealicense.com/licenses/mit/)
