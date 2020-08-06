import { Signer } from 'ethers'
import { ContractReceipt, Contract } from 'ethers/contract'
import { formatUnits, parseUnits, BigNumber } from 'ethers/utils'

import { ethers } from '@nomiclabs/buidler'

export function toNum(value: BigNumber, decimals = 18): number {
  return parseFloat(formatUnits(value, decimals))
}

export function toBigNum(value: number, decimals = 18): BigNumber {
  return parseUnits(`${value}`, decimals)
}

export function returnValueFromTxReceipt(
  receipt: ContractReceipt,
  eventName: string,
  argName: string
): any {
  const event = receipt.events?.find(e => e.event === eventName) as any
  return event.args[`${argName}`]
}

export function stringifyJson(json: any): string {
  return JSON.stringify(json, null, 2)
}

export async function deployContract(
  contractName: string,
  params: any[] = []
): Promise<Contract> {
  const factory = await ethers.getContractFactory(contractName)

  return (await factory.deploy(...params)).deployed()
}

export async function getContract(
  contractName: string,
  address: string
): Promise<Contract> {
  const factory = await ethers.getContractFactory(contractName)
  return factory.attach(address)
}

export async function getFirstSigner(): Promise<Signer> {
  const signers = await ethers.getSigners()
  const signer = signers[0]

  await signer.getAddress()

  return signer
}
